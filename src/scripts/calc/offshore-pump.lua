local calc_util = require("scripts.calc.util")

return function(rates, entity, emissions_per_second)
  local entity_prototype = entity.prototype
  local fluid_prototype = entity_prototype.fluid
  local fluid_name = fluid_prototype.name
  local amount = entity_prototype.pumping_speed * 60 -- pumping speed per second
  calc_util.add_rate(rates.materials, "output", "fluid", fluid_name, fluid_prototype.localised_name, amount)

  return emissions_per_second
end

