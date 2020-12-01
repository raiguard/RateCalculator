local calc_util = require("scripts.calc.util")

return function(rates, entity)
  local max_energy_usage = entity.prototype.max_energy_usage
  calc_util.add_rate(
    rates.inputs,
    "entity",
    entity.name,
    entity.localised_name,
    max_energy_usage * 60
  )
end