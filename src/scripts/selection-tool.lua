local selection_tool = {}

local rcalc_gui = require("scripts.rcalc-gui")

function selection_tool.process_selection(player_index, area, entities, surface)
  local player = game.get_player(player_index)
  local player_table = global.players[player_index]

  local prototypes = {
    fluid = game.fluid_prototypes,
    item = game.item_prototypes
  }

  local ingredients = {__size=0}
  local products = {__size=0}

  for i = 1, #entities do
    local entity = entities[i]
    local entity_type = entity.type

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
            ingredients[combined_name] = {type=ingredient.type, name=ingredient.name, localised_name=prototypes[ingredient.type][ingredient.name].localised_name,
              amount=amount}
            ingredients.__size = ingredients.__size + 1
          end
        end

        local product_base_unit = ingredient_base_unit * (entity.productivity_bonus + 1)
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
    elseif entity_type == "lab" then

    elseif entity_type == "mining-drill" then

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