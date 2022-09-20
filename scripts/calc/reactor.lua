local calc_util = require("scripts.calc.util")

return function(rates, entity, emissions_per_second)
  calc_util.add_rate(
    rates.heat,
    "output",
    "entity",
    entity.name,
    entity.localised_name,
    entity.prototype.max_energy_usage * (entity.neighbour_bonus + 1)
  )

  return emissions_per_second
end
