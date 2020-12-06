local calc_util = require("scripts.calc.util")

return function(rates, entity, emissions_per_second)
  calc_util.add_rate(
    rates,
    "input",
    "entity",
    entity.name,
    entity.localised_name,
    entity.prototype.max_energy_usage
  )

  -- from testing, it appears that heat energy sources never produce pollution
  return emissions_per_second
end