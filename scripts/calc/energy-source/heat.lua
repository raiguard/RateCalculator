local calc_util = require("__RateCalculator__.scripts.calc.util")

--- @param entity LuaEntity
return function(rates, entity, emissions_per_second)
  calc_util.add_rate(
    rates,
    "input",
    "entity",
    entity.name,
    entity.localised_name,
    entity.prototype.max_energy_usage * (1 + entity.consumption_bonus)
  )

  -- From testing, it appears that heat energy sources never produce pollution
  return emissions_per_second
end
