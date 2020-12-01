local calc_util = require("scripts.calc.util")

return function(rates, entity)
  local entity_prototype = entity.prototype
  local fluid_prototype = entity_prototype.fluid
  local fluid_name = fluid_prototype.name
  local amount = entity_prototype.pumping_speed * 60 -- pumping speed per second
  calc_util.add_rate(rates.outputs, "fluid", fluid_name, fluid_prototype.localised_name, amount)
end

