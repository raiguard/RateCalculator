local calc_util = require("__RateCalculator__.scripts.calc.util")

return function(rates, entity, emissions_per_second)
  calc_util.add_rate(rates, "input", "entity", entity.name, entity.localised_name, entity.prototype.max_energy_usage)

  -- From testing, it appears that heat energy sources never produce pollution
  return emissions_per_second
end
