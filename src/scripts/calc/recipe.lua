local calc_util = require("scripts.calc.util")

--- @param rates table
--- @param entity LuaEntity
--- @param emissions_per_second number
--- @param prototypes table<string, table<string, LuaEntityPrototype>>
return function(rates, entity, emissions_per_second, prototypes)
  --- @type LuaRecipe
  local recipe = entity.get_recipe() or (entity.type == "furnace" and entity.previous_recipe)

  if recipe then
    -- The game engine has a hard limit of one craft per tick, so the maximum possible crafts per second is 60
    local crafts_per_second = math.min(entity.crafting_speed / recipe.energy, 60)

    for _, ingredient in ipairs(recipe.ingredients) do
      local amount = ingredient.amount * crafts_per_second
      local ingredient_type = ingredient.type
      local ingredient_name = ingredient.name
      local ingredient_localised_name = prototypes[ingredient_type][ingredient_name].localised_name
      calc_util.add_rate(rates.materials, "input", ingredient_type, ingredient_name, ingredient_localised_name, amount)
    end

    local productivity = (entity.productivity_bonus + 1)
    for _, product in ipairs(recipe.products) do
      local adjusted_crafts_per_second = crafts_per_second * (product.probability or 1)

      -- Take the average amount if there is a min and max
      local amount = product.amount or (product.amount_max - ((product.amount_max - product.amount_min) / 2))
      local catalyst_amount = product.catalyst_amount or 0

      -- Catalysts are not affected by productivity
      local amount = catalyst_amount + ((amount - catalyst_amount) * productivity) * adjusted_crafts_per_second

      local product_type = product.type
      local product_name = product.name
      local product_localised_name = prototypes[product_type][product_name].localised_name
      calc_util.add_rate(rates.materials, "output", product_type, product_name, product_localised_name, amount)
    end

    return emissions_per_second * recipe.prototype.emissions_multiplier * (1 + entity.pollution_bonus)
  end

  return emissions_per_second
end
