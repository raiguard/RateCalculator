local calc_util = require("scripts.calc.util")

return function(rates, entity, emissions_per_second, prototypes, research_data)
  if research_data then
    --[[
      due to a bug with entity_speed_bonus, we must subtract the force's lab speed bonus and convert it to a
      multiplicative relationship
    ]]
    local lab_multiplier = (
      research_data.multiplier * (
        (entity.speed_bonus + 1 - research_data.speed_modifier) * (research_data.speed_modifier + 1)
      )
    )

    for _, ingredient in ipairs(research_data.ingredients) do
      local amount = ((ingredient.amount * lab_multiplier) / prototypes.item[ingredient.name].durability)
      local ingredient_type = ingredient.type
      local ingredient_name = ingredient.name
      local ingredient_localised_name = prototypes[ingredient_type][ingredient_name].localised_name
      calc_util.add_rate(rates.inputs, ingredient_type, ingredient_name, ingredient_localised_name, amount)
    end
  end

  return emissions_per_second
end

