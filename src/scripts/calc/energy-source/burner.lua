local calc_util = require("scripts.calc.util")

return function(rates, entity)
  local entity_prototype = entity.prototype
  local burner_prototype = entity_prototype.burner_prototype

  local burner = entity.burner
  local currently_burning = burner.currently_burning

  local max_energy_usage = entity_prototype.max_energy_usage

  if currently_burning then
    local burns_per_second = 1 / (currently_burning.fuel_value / max_energy_usage / burner_prototype.effectivity / 60)
    calc_util.add_rate(
      rates.inputs,
      "item",
      currently_burning.name,
      currently_burning.localised_name,
      burns_per_second
    )
  end
end