local selection_tool = {}

local constants = require("constants")

local table = require("__flib__.table")

local player_data = require("scripts.player-data")
local rcalc_gui = require("scripts.gui")

function selection_tool.setup_selection(player, player_table, area, entities, surface)
  local force = player.force
  local current_research = force.current_research
  local research_data
  if current_research then
    research_data = {
      ingredients = current_research.research_unit_ingredients,
      multiplier = 1 / (current_research.research_unit_energy / 60),
      speed_modifier = force.laboratory_speed_modifier
    }
  end

  if #entities > 0 then
    player_table.iteration_data = {
      area = area,
      entities = entities,
      rate_data = {inputs = {__size = 0}, outputs = {__size = 0}},
      render_objects = {
        rendering.draw_rectangle{
          color = {r = 1, g = 1, b = 0},
          width = 4,
          filled = false,
          left_top = area.left_top,
          right_bottom = area.right_bottom,
          surface = surface,
          players = {player.index},
          draw_on_ground = true
        }
      },
      research_data = research_data,
      started_tick = game.tick,
      surface = surface
    }
    player_data.register_for_iteration(player.index, player_table)
    return true -- register on_tick
  end
end

function selection_tool.iterate(players_to_iterate)
  local prototypes = {
    entity = game.entity_prototypes,
    fluid = game.fluid_prototypes,
    item = game.item_prototypes
  }
  local player_tables = global.players
  local iterations_per_player = math.max(global.settings.entities_per_tick / table_size(players_to_iterate), 1)
  for player_index in pairs(players_to_iterate) do
    local player = game.get_player(player_index)
    local player_table = player_tables[player_index]
    local iteration_data = player_table.iteration_data
    local entities = iteration_data.entities
    local rate_data = iteration_data.rate_data
    local research_data = iteration_data.research_data
    local render_objects = iteration_data.render_objects
    local surface = iteration_data.surface

    local next_index = table.for_n_of(entities, iteration_data.next_index, iterations_per_player, function(entity)
      if not entity.valid then return end
      local registered = selection_tool.process_entity(entity, rate_data, prototypes, research_data)
      -- add indicator dot
      local circle_color = registered and {r = 1, g = 1, b = 0} or {r = 1, g = 0, b = 0}
      render_objects[#render_objects+1] = rendering.draw_circle{
        color = circle_color,
        radius = 0.2,
        filled = true,
        target = entity,
        surface = surface,
        players = {player_index}
      }
    end)

    if next_index then
      iteration_data.next_index = next_index
    else
      if rate_data.inputs.__size == 0 and rate_data.outputs.__size == 0 then
        player.print{"rcalc-message.no-compatible-machines-in-selection"}
      else
        rate_data.inputs.__size = nil
        rate_data.outputs.__size = nil
        local function sorter(a, b)
          return a.amount > b.amount
        end
        -- this is an ugly horrible dirty way to convert a table into an array (loses key references)
        local sorted_data = {
          inputs = table.filter(rate_data.inputs, function() return true end, true),
          outputs = table.filter(rate_data.outputs, function() return true end, true)
        }
        table.sort(sorted_data.inputs, sorter)
        table.sort(sorted_data.outputs, sorter)
        player_table.selection_data = {
          sorted = sorted_data,
          hash = rate_data
        }

        rcalc_gui.update_contents(player_table)
        if not player_table.flags.gui_open then
          rcalc_gui.open(player, player_table)
        end
      end
      selection_tool.stop_iteration(player.index, player_table)
    end
  end
end

local function add_rate(tbl, type, name, localised_name, amount)
  local combined_name = type.."."..name
  local override = constants.rate_key_overrides[combined_name]
  if override then
    type = override[1]
    name = override[2]
    combined_name = override[1].."."..override[2]
  end
  local data = tbl[combined_name]
  if data then
    data.amount = data.amount + amount
    data.machines = data.machines + 1
  else
    tbl[combined_name] = {
      type = type,
      name = name,
      localised_name = localised_name,
      amount = amount,
      machines = 1
    }
    tbl.__size = tbl.__size + 1
  end
end

function selection_tool.process_entity(entity, rate_data, prototypes, research_data)
  local success = false

  local inputs = rate_data.inputs
  local outputs = rate_data.outputs

  local entity_type = entity.type
  local entity_speed_bonus = entity.speed_bonus
  local entity_productivity_bonus = entity.productivity_bonus

  -- power
  local entity_prototype = prototypes.entity[entity.name]
  do
    local max_energy_usage = entity_prototype.max_energy_usage
    local electric_energy_source_prototype = entity_prototype.electric_energy_source_prototype
    if
      entity_type ~= "burner-generator"
      and entity_type ~= "electric-energy-interface"
      and electric_energy_source_prototype
      and max_energy_usage
      and max_energy_usage > 0
    then
      local consumption_bonus = (entity.consumption_bonus + 1)
      success = true
      add_rate(
        inputs,
        "entity",
        entity.name,
        entity_prototype.localised_name,
        (max_energy_usage * consumption_bonus) + electric_energy_source_prototype.drain
      )
    end

    local max_energy_production = entity_prototype.max_energy_production
    if max_energy_production > 0 then
      if max_energy_production > 0 then
        local entity_name = entity.name
        add_rate(outputs, "entity", entity_name, entity_prototype.localised_name, max_energy_production)
        success = true
      end
    end
  end

  -- materials
  if entity_type == "assembling-machine" or entity_type == "furnace" or entity_type == "rocket-silo" then
    local recipe = entity.get_recipe()
    if recipe then
      local material_base_unit = ((60 / recipe.energy) * entity.crafting_speed) / 60
      for _, ingredient in ipairs(recipe.ingredients) do
        local amount = ingredient.amount * material_base_unit
        local ingredient_type = ingredient.type
        local ingredient_name = ingredient.name
        local ingredient_localised_name = prototypes[ingredient_type][ingredient_name].localised_name
        add_rate(inputs, ingredient_type, ingredient_name, ingredient_localised_name, amount)
      end

      local productivity = (entity_productivity_bonus + 1)
      for _, product in ipairs(recipe.products) do
        local base_unit = material_base_unit * (product.probability or 1)

        local amount = product.amount or (product.amount_max - ((product.amount_max - product.amount_min) / 2))
        local catalyst_amount = product.catalyst_amount or 0
        amount = ((amount - catalyst_amount) * base_unit * productivity) + (catalyst_amount * base_unit)

        local product_type = product.type
        local product_name = product.name
        local product_localised_name = prototypes[product_type][product_name].localised_name
        add_rate(outputs, product_type, product_name, product_localised_name, amount)
      end
      success = true
    end
  elseif entity_type == "lab" then
    if research_data then
      rate_data.includes_lab = true
      --[[
        due to a bug with entity_speed_bonus, we must subtract the force's lab speed bonus and convert it to a
        multiplicative relationship
      ]]
      local lab_multiplier = (
        research_data.multiplier * (
          (entity_speed_bonus + 1 - research_data.speed_modifier) * (research_data.speed_modifier + 1)
        )
      )

      for _, ingredient in ipairs(research_data.ingredients) do
        local amount = ((ingredient.amount * lab_multiplier) / prototypes.item[ingredient.name].durability)
        local ingredient_type = ingredient.type
        local ingredient_name = ingredient.name
        local ingredient_localised_name = prototypes[ingredient_type][ingredient_name].localised_name
        add_rate(inputs, ingredient_type, ingredient_name, ingredient_localised_name, amount)
      end

      success = true
    end
  elseif entity_type == "mining-drill" then
    -- look for resource entities under the drill
    local position = entity.position
    local radius = entity_prototype.mining_drill_radius + 0.01
    local resource_entities = entity.surface.find_entities_filtered{
      area = {
        left_top = {
          x = position.x - radius,
          y = position.y - radius
        },
        right_bottom = {
          x = position.x + radius,
          y = position.y + radius
        }
      },
      type = "resource"
    }
    local resource_entities_len = #resource_entities
    if resource_entities_len == 0 then return false end

    -- process entities
    local resources = {}
    local num_resource_entities = 0
    for i = 1, resource_entities_len do
      local resource = resource_entities[i]
      local resource_name = resource.name

      -- check if this resource has already been processed
      local resource_data = resources[resource_name]
      if resource_data then
        resource_data.occurances = resource_data.occurances + 1
        num_resource_entities = num_resource_entities + 1
      else
        local resource_prototype = resource.prototype

        -- check if this resource can be mined by this drill
        if entity_prototype.resource_categories[resource_prototype.resource_category] then
          num_resource_entities = num_resource_entities + 1
          local mineable_properties = resource_prototype.mineable_properties

          -- add data to table
          resources[resource_name] = {
            occurances = 1,
            products = mineable_properties.products,
            required_fluid = nil,
            mining_time = mineable_properties.mining_time
          }
          resource_data = resources[resource_name]

          -- account for infinite resource yield
          if resource_prototype.infinite_resource then
            resource_data.mining_time = (
              resource_data.mining_time / (resource.amount / resource_prototype.normal_resource_amount)
            )
          end

          -- add required fluid
          local required_fluid = mineable_properties.required_fluid
          if required_fluid then
            resource_data.required_fluid = {
              name = required_fluid,
              amount = mineable_properties.fluid_amount / 10 -- ten mining operations per consumed
            }
          end
        end
      end
    end

    -- process resource entities
    if num_resource_entities > 0 then
      local drill_multiplier = (
        entity_prototype.mining_speed * (entity_speed_bonus + 1) * (entity_productivity_bonus + 1)
      )

      -- iterate each resource
      for _, resource_data in pairs(resources) do
        local resource_multiplier =  (
          (drill_multiplier / resource_data.mining_time) * (resource_data.occurances / num_resource_entities)
        )

        -- add required fluid to inputs
        local required_fluid = resource_data.required_fluid
        if required_fluid then
          -- productivity does not apply to ingredients
          local fluid_per_second = required_fluid.amount * resource_multiplier / (entity_productivity_bonus + 1)

          -- add to inputs table
          local fluid_name = required_fluid.name
          add_rate(inputs, "fluid", fluid_name, prototypes.fluid[fluid_name].localised_name, fluid_per_second)
        end

        -- iterate each product
        for _, product in pairs(resource_data.products) do
          -- get rate per second for this product on this drill
          local product_per_second
          if product.amount then
            product_per_second = product.amount * resource_multiplier
          else
            product_per_second = (
              (product.amount_max - ((product.amount_max - product.amount_min) / 2)) * resource_multiplier
            )
          end

          -- add to outputs table
          local product_type = product.type
          local product_name = product.name
          local product_localised_name = prototypes[product_type][product_name].localised_name
          add_rate(outputs, product_type, product_name, product_localised_name, product_per_second)
        end
      end
      success = true
    end
  elseif entity_type == "offshore-pump" then
    local fluid_prototype = entity_prototype.fluid
    local fluid_name = fluid_prototype.name
    local amount = entity_prototype.pumping_speed * 60 -- pumping speed per second
    add_rate(outputs, "fluid", fluid_name, fluid_prototype.localised_name, amount)
    success = true
  elseif entity_type == "generator" then
    for _, fluidbox in ipairs(entity_prototype.fluidbox_prototypes) do
      local filter = fluidbox.filter
      if filter then
        local fluid_name = filter.name
        local fluid_usage = entity_prototype.fluid_usage_per_tick * 60
        add_rate(inputs, "fluid", fluid_name, prototypes.fluid[fluid_name].localised_name, fluid_usage)
        success = true
      end
    end
  elseif entity_type == "electric-energy-interface" then
    local production = entity.power_production
    local usage = entity.power_usage

    local entity_name = entity.name

    if production > 0 then
      add_rate(outputs, "entity", entity_name, entity_prototype.localised_name, production)
      success = true
    end
    if usage > 0 then
      add_rate(inputs, "entity", entity_name, entity_prototype.localised_name, usage)
      success = true
    end
  end

  return success
end

function selection_tool.stop_iteration(player_index, player_table)
  local objects = player_table.iteration_data.render_objects
  local destroy = rendering.destroy
  for i = 1, #objects do
    destroy(objects[i])
  end
  player_data.deregister_from_iteration(player_index, player_table)
end

return selection_tool
