local calc_util = require("scripts.calc.util")

return function(rates, entity, _, emissions_per_second)
  local max_energy_usage = entity.prototype.max_energy_usage
  calc_util.add_rate(
    rates.inputs,
    "entity",
    entity.name,
    entity.localised_name,
    max_energy_usage * 60
  )

  -- heat energy sources don't actually produce pollution
  return emissions_per_second
end