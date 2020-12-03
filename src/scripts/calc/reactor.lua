local calc_util = require("scripts.calc.util")

return function(rates, entity, emissions_per_second)
  local entity_prototype = entity.prototype

  local max_energy_usage = entity_prototype.max_energy_usage

  -- the game does not provide this for reactors, so we must calculate it ourself
  local max_energy_production = max_energy_usage * (entity.neighbour_bonus + 1)

  calc_util.add_rate(
    rates,
    "output",
    "entity",
    entity.name,
    entity.localised_name,
    max_energy_production * 60
  )

  return emissions_per_second
end
