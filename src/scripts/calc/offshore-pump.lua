local calc_util = require("scripts.calc.util")

return function(rates, entity, emissions_per_second)
  local entity_prototype = entity.prototype
  local fluid_prototype = entity_prototype.fluid

  calc_util.add_rate(
    rates.materials,
    "output",
    "fluid",
    fluid_prototype.name,
    fluid_prototype.localised_name,
    entity_prototype.pumping_speed * 60,
    "entity/" .. entity.name
  )

  return emissions_per_second
end
