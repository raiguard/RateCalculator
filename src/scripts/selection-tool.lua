local selection_tool = {}

local rcalc_gui = require("scripts.rcalc-gui")

function selection_tool.process_selection(player_index, area, entities, surface)
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]

  local force = player.force
  local current_research = force.current_research
  local research_multiplier = 0
  if current_research then
    research_multiplier = current_research.research_unit_energy / 60 / 60
  end

  local prototypes = {
    fluid = game.fluid_prototypes,
    item = game.item_prototypes
  }

  local inputs = {__size=0}
  local outputs = {__size=0}

  for i = 1, #entities do
    -- TODO create bounding box and entity highlights
    local entity = entities[i]
    local entity_type = entity.type

    local speed_bonus = entity.speed_bonus
    local productivity_bonus = entity.productivity_bonus

    if entity_type == "assembling-machine" or entity_type == "furnace" then
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
            inputs.__size = inputs.__size + 1
          end
        end

        local product_base_unit = ingredient_base_unit * (productivity_bonus + 1)
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
            outputs.__size = outputs.__size + 1
          end
        end
      end
    elseif entity_type == "lab" and current_research then
      local lab_multiplier = (research_multiplier * (speed_bonus + 1) * (productivity_bonus + 1)) / 60

      for _, ingredient in ipairs(current_research.research_unit_ingredients) do
        local amount = ingredient.amount * lab_multiplier
        local combined_name = ingredient.type..","..ingredient.name
        local input_data = inputs[combined_name]
        if input_data then
          input_data.amount = input_data.amount + amount
          input_data.machines = input_data.machines + 1
        else
          inputs[combined_name] = {type=ingredient.type, name=ingredient.name,
            localised_name=prototypes[ingredient.type][ingredient.name].localised_name, amount=amount, machines=1}
          inputs.__size = inputs.__size + 1
        end
      end
    elseif entity_type == "mining-drill" then
      -- TODO search and account for all resources under the drill
      local prototype = entity.prototype

      -- mining speed, including bonuses
      local mining_speed = prototype.mining_speed * (speed_bonus + 1) * (productivity_bonus + 1)

      -- apply mining target stats
      local mining_target = entity.mining_target
      if mining_target then
        local target_prototype = mining_target.prototype
        local target_mining_properties = target_prototype.mineable_properties

        mining_speed = mining_speed * target_mining_properties.mining_time

        -- account for infinite resource yield
        -- TODO double check this, it might be slightly wrong
        if target_prototype.infinite_resource then
          mining_speed =  mining_speed * (mining_target.amount / 300000)
        end

        for _, product in ipairs(target_mining_properties.products) do
          -- calculate amount
          local amount = product.amount
          if amount then
            amount = amount * mining_speed
          else
            amount = (product.amount_max - ((product.amount_max - product.amount_min) / 2)) * mining_speed
          end
          -- save product
          local combined_name = product.type..","..product.name
          local output_data = outputs[combined_name]
          if output_data then
            output_data.amount = output_data.amount + amount
            output_data.machines = output_data.machines + 1
          else
            outputs[combined_name] = {type=product.type, name=product.name, localised_name=prototypes[product.type][product.name].localised_name,
              amount=amount, machines=1}
            outputs.__size = outputs.__size + 1
          end
        end
      end
    elseif entity_type == "offshore-pump" then
      local prototype = entity.prototype
      local fluid = prototype.fluid
      local fluid_name = fluid.name
      local combined_name = "fluid,"..fluid_name
      local output_data = outputs[combined_name]
      local amount = prototype.pumping_speed * 60 -- pumping speed per second
      if output_data then
        output_data.amount = output_data.amount + amount
        output_data.machines = output_data.machines + 1
      else
        outputs[combined_name] = {type="fluid", name=fluid_name, localised_name=fluid.localised_name, amount=amount, machines=1}
        outputs.__size = inputs.__size + 1
      end
    end
  end

  if inputs.__size == 0 and outputs.__size == 0 then
    player.print{"rcalc-message.no-recipes-in-selection"}
  else
    if player_table.flags.gui_open then
      rcalc_gui.destroy(player, player_table)
    end
    rcalc_gui.create(player, player_table, {inputs=inputs, outputs=outputs})
  end
end

return selection_tool