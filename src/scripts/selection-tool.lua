local selection_tool = {}

local player_data = require("scripts.player-data")
local rcalc_gui = require("scripts.rcalc-gui")

-- TODO sort by rate

function selection_tool.setup_selection(player, player_table, area, entities, surface)
  local force = player.force
  local current_research = force.current_research
  local research_data = {}
  if current_research then
    research_data = {
      ingredients = current_research.research_unit_ingredients,
      multiplier = current_research.research_unit_energy / 60 / 60
    }
  end

  if #entities > 0 then
    player_table.iteration_data = {
      area = area,
      entities = entities,
      next_index = 1,
      rate_data = {inputs={}, inputs_size=0, outputs={}, outputs_size=0},
      registry_index = player_data.register_for_iteration(player.index, player_table),
      render_objects = {
        rendering.draw_rectangle{
          color = {r=1, g=1, b=0},
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
  end
end

function selection_tool.iterate(players_to_iterate, players_to_iterate_len)
  local prototypes = {
    fluid = game.fluid_prototypes,
    item = game.item_prototypes
  }
  local player_tables = global.players
  local iterations_per_player = math.max(global.settings.entities_per_tick / players_to_iterate_len, 1)
  for players_to_iterate_index = 1, players_to_iterate_len do
    local player_index = players_to_iterate[players_to_iterate_index]
    local player = game.get_player(player_index)
    local player_table = player_tables[player_index]
    local iteration_data = player_table.iteration_data
    local entities = iteration_data.entities
    local next_index = iteration_data.next_index
    local rate_data = iteration_data.rate_data
    local research_data = iteration_data.research_data
    local render_objects = iteration_data.render_objects
    local surface = iteration_data.surface
    for entity_index = next_index, next_index + iterations_per_player do
      local entity = entities[entity_index]
      if entity then
        local registered = selection_tool.process_entity(entity, rate_data, prototypes, research_data)
        -- add indicator dot
        local circle_color = registered and {r=1, g=1, b=0} or {r=1, g=0, b=0}
        render_objects[#render_objects+1] = rendering.draw_circle{
          color = circle_color,
          radius = 0.2,
          filled = true,
          target = entity,
          surface = surface,
          players = {player_index}
        }
      else
        if rate_data.inputs_size == 0 and rate_data.outputs_size == 0 then
          player.print{"rcalc-message.no-compatible-machines-in-selection"}
        else
          player_table.selection_data = rate_data
          rcalc_gui.update_contents(player, player_table)
          if not player_table.flags.gui_open then
            rcalc_gui.open(player, player_table)
          end
        end
        selection_tool.stop_iteration(player_table)
        break
      end
    end
    iteration_data.next_index = next_index + iterations_per_player + 1
  end
end

function selection_tool.process_entity(entity, rate_data, prototypes, research_data)
  local inputs = rate_data.inputs
  local outputs = rate_data.outputs

  local entity_type = entity.type
  local entity_speed_bonus = entity.speed_bonus
  local entity_productivity_bonus = entity.productivity_bonus

  if entity_type == "assembling-machine" or entity_type == "furnace" or entity_type == "rocket-silo" then
    local recipe = entity.get_recipe()
    if recipe then
      local ingredient_base_unit = ((60 / recipe.energy) * entity.crafting_speed) / 60
      for _, ingredient in ipairs(recipe.ingredients) do
        local combined_name = ingredient.type..","..ingredient.name
        local input_data = inputs[combined_name]
        local amount = ingredient.amount * ingredient_base_unit
        if input_data then
          input_data.amount = input_data.amount + amount
          input_data.machines = input_data.machines + 1
        else
          inputs[combined_name] = {type=ingredient.type, name=ingredient.name,
            localised_name=prototypes[ingredient.type][ingredient.name].localised_name, amount=amount, machines=1}
          rate_data.inputs_size = rate_data.inputs_size + 1
        end
      end

      local product_base_unit = ingredient_base_unit * (entity_productivity_bonus + 1)
      for _, product in ipairs(recipe.products) do
        local base_unit = product_base_unit * (product.probability or 1)

        local amount = product.amount
        if amount then
          amount = amount * base_unit
        else
          amount = (product.amount_max - ((product.amount_max - product.amount_min) / 2)) * base_unit
        end

        local combined_name = product.type..","..product.name
        local output_data = outputs[combined_name]
        if output_data then
          output_data.amount = output_data.amount + amount
          output_data.machines = output_data.machines + 1
        else
          outputs[combined_name] = {type=product.type, name=product.name, localised_name=prototypes[product.type][product.name].localised_name,
            amount=amount, machines=1}
          rate_data.outputs_size = rate_data.outputs_size + 1
        end
      end
      return true
    end
    return false
  elseif entity_type == "lab" then
    if research_data then
      rate_data.includes_lab = true
      local lab_multiplier = (research_data.multiplier * (entity_speed_bonus + 1) * (entity_productivity_bonus + 1)) / 60

      for _, ingredient in ipairs(research_data.ingredients) do
        local amount = ingredient.amount * lab_multiplier
        local combined_name = ingredient.type..","..ingredient.name
        local input_data = inputs[combined_name]
        if input_data then
          input_data.amount = input_data.amount + amount
          input_data.machines = input_data.machines + 1
        else
          inputs[combined_name] = {type=ingredient.type, name=ingredient.name,
            localised_name=prototypes[ingredient.type][ingredient.name].localised_name, amount=amount, machines=1}
          rate_data.inputs_size = rate_data.inputs_size + 1
        end
      end

      return true
    else
      return false
    end
  elseif entity_type == "mining-drill" then
    local entity_prototype = entity.prototype

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
            resource_data.mining_time =  resource_data.mining_time * (resource.amount / 300000)
          end

          -- add required fluid
          local required_fluid = mineable_properties.required_fluid
          if required_fluid then
            resource_data.required_fluid = {
              name = required_fluid,
              amount = mineable_properties.fluid_amount
            }
          end
        end
      end
    end

    -- process resource entities
    if num_resource_entities > 0 then
      local drill_multiplier = entity_prototype.mining_speed * (entity_speed_bonus + 1) * (entity_productivity_bonus + 1)

      -- iterate each resource
      for _, resource_data in pairs(resources) do
        local resource_multiplier =  (drill_multiplier / resource_data.mining_time) * (resource_data.occurances / num_resource_entities)

        -- add required fluid to inputs
        local required_fluid = resource_data.required_fluid
        if required_fluid then
          local fluid_per_second = required_fluid.amount * resource_multiplier

          -- add to inputs table
          local combined_name = "fluid,"..required_fluid.name
          local input_data = inputs[combined_name]
          if input_data then
            input_data.amount = input_data.amount + fluid_per_second
            input_data.machines = input_data.machines + 1
          else
            inputs[combined_name] = {type="fluid", name=required_fluid.name, localised_name=prototypes.fluid[required_fluid.name].localised_name,
              amount=fluid_per_second, machines=1}
            rate_data.outputs_size = rate_data.outputs_size + 1
          end
        end

        -- iterate each product
        for _, product in pairs(resource_data.products) do
          -- get rate per second for this product on this drill
          local product_per_second
          if product.amount then
            product_per_second = product.amount * resource_multiplier
          else
            product_per_second = (product.amount_max - ((product.amount_max - product.amount_min) / 2)) * resource_multiplier
          end

          -- add to outputs table
          local combined_name = product.type..","..product.name
          local output_data = outputs[combined_name]
          if output_data then
            output_data.amount = output_data.amount + product_per_second
            output_data.machines = output_data.machines + 1
          else
            outputs[combined_name] = {type=product.type, name=product.name, localised_name=prototypes[product.type][product.name].localised_name,
              amount=product_per_second, machines=1}
            rate_data.outputs_size = rate_data.outputs_size + 1
          end
        end
      end
      return true
    else
      return false
    end
  elseif entity_type == "offshore-pump" then
    local prototype = entity.prototype
    local fluid = prototype.fluid
    local fluid_name = fluid.name
    local combined_name = "fluid,"..fluid_name
    local amount = prototype.pumping_speed * 60 -- pumping speed per second
    local output_data = outputs[combined_name]
    if output_data then
      output_data.amount = output_data.amount + amount
      output_data.machines = output_data.machines + 1
    else
      outputs[combined_name] = {type="fluid", name=fluid_name, localised_name=fluid.localised_name, amount=amount, machines=1}
      rate_data.outputs_size = rate_data.outputs_size + 1
    end
    return true
  end
end

function selection_tool.stop_iteration(player_table)
  local objects = player_table.iteration_data.render_objects
  local destroy = rendering.destroy
  for i = 1, #objects do
    destroy(objects[i])
  end
  table.remove(global.players_to_iterate, player_table.iteration_data.registry_index)
  player_table.iteration_data = nil

  player_table.flags.iterating = false
end

return selection_tool