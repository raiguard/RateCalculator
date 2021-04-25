local calc_util = require("scripts.calc.util")

return function(rates, entity, emissions_per_second, prototypes)
  local recipe = entity.get_recipe() or (entity.type == "furnace" and entity.previous_recipe)

  if recipe then
    local material_base_unit = ((60 / recipe.energy) * entity.crafting_speed) / 60
    for _, ingredient in ipairs(recipe.ingredients) do
      local amount = ingredient.amount * material_base_unit
      local ingredient_type = ingredient.type
      local ingredient_name = ingredient.name
      local ingredient_localised_name = prototypes[ingredient_type][ingredient_name].localised_name
      calc_util.add_rate(rates.materials, "input", ingredient_type, ingredient_name, ingredient_localised_name, amount)
    end

    local productivity = (entity.productivity_bonus + 1)
    for _, product in ipairs(recipe.products) do
      local base_unit = material_base_unit * (product.probability or 1)

      local amount = product.amount or (product.amount_max - ((product.amount_max - product.amount_min) / 2))
      local catalyst_amount = product.catalyst_amount or 0
      amount = ((amount - catalyst_amount) * base_unit * productivity) + (catalyst_amount * base_unit)

      local product_type = product.type
      local product_name = product.name
      local product_localised_name = prototypes[product_type][product_name].localised_name
      calc_util.add_rate(rates.materials, "output", product_type, product_name, product_localised_name, amount)
    end
    return emissions_per_second * recipe.prototype.emissions_multiplier * (1 + entity.pollution_bonus)
  end

  return emissions_per_second
end
