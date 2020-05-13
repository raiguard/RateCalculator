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

  local ingredients = {__size=0}
  local products = {__size=0}

  for i = 1, #entities do
    -- TODO create bounding box and entity highlights
    local entity = entities[i]
    local entity_type = entity.type

    local speed_bonus = entity.speed_bonus
    local productivity_bonus = entity.productivity_bonus

    if entity_type == "assembling-machine" or entity_type == "furnace" then
      local recipe = entity.get_recipe()
      if recipe then
        local ingredient_base_unit = (60 / recipe.energy) * entity.crafting_speed
        for _, ingredient in ipairs(recipe.ingredients) do
          local combined_name = ingredient.type..","..ingredient.name
          local ingredient_data = ingredients[combined_name]
          local amount = ingredient.amount * ingredient_base_unit
          if ingredient_data then
            ingredient_data.amount = ingredient_data.amount + amount
          else
            ingredients[combined_name] = {type=ingredient.type, name=ingredient.name,
              localised_name=prototypes[ingredient.type][ingredient.name].localised_name, amount=amount}
            ingredients.__size = ingredients.__size + 1
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
          local product_data = products[combined_name]
          if product_data then
            product_data.amount = product_data.amount + amount
            product_data.machines = product_data.machines + 1
          else
            products[combined_name] = {type=product.type, name=product.name, localised_name=prototypes[product.type][product.name].localised_name,
              amount=amount, machines=1}
            products.__size = products.__size + 1
          end
        end
      end
    elseif entity_type == "lab" and current_research then
      -- * GOAL: how many packs are consumed by each lab per minute for the current research
      local lab_multiplier = research_multiplier * (speed_bonus + 1) * (productivity_bonus + 1)

      for _, ingredient in ipairs(current_research.research_unit_ingredients) do
        local amount = ingredient.amount * lab_multiplier
        local combined_name = ingredient.type..","..ingredient.name
        local ingredient_data = ingredients[combined_name]
        if ingredient_data then
          ingredient_data.amount = ingredient_data.amount + amount
        else
          ingredients[combined_name] = {type=ingredient.type, name=ingredient.name,
            localised_name=prototypes[ingredient.type][ingredient.name].localised_name, amount=amount}
          ingredients.__size = ingredients.__size + 1
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

        -- convert to per-minute
        mining_speed = mining_speed * 60

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
          local product_data = products[combined_name]
          if product_data then
            product_data.amount = product_data.amount + amount
            product_data.machines = product_data.machines + 1
          else
            products[combined_name] = {type=product.type, name=product.name, localised_name=prototypes[product.type][product.name].localised_name,
              amount=amount, machines=1}
            products.__size = products.__size + 1
          end
        end
      end
    elseif entity_type == "offshore-pump" then
      local prototype = entity.prototype
      local fluid = prototype.fluid
      local fluid_name = fluid.name
      local combined_name = "fluid,"..fluid_name
      local ingredient_data = ingredients[combined_name]
      local amount = prototype.pumping_speed * 60 * 60 -- pumping speed per minute
      if ingredient_data then
        ingredient_data.amount = ingredient_data.amount + amount
      else
        ingredients[combined_name] = {type="fluid", name=fluid_name, localised_name=fluid.localised_name, amount=amount}
        ingredients.__size = ingredients.__size + 1
      end
    end
  end

  if ingredients.__size == 0 and products.__size == 0 then
    player.print{"rcalc-message.no-recipes-in-selection"}
  else
    if player_table.flags.gui_open then
      rcalc_gui.destroy(player, player_table)
    end
    rcalc_gui.create(player, player_table, {ingredients=ingredients, products=products})
  end
end

return selection_tool