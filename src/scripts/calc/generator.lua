local calc_util = require("scripts.calc.util")

return function(rates, entity, prototypes)
  local entity_prototype = entity.prototype
  for _, fluidbox in ipairs(entity_prototype.fluidbox_prototypes) do
    local filter = fluidbox.filter
    if filter then
      local fluid_name = filter.name
      local fluid_usage = entity_prototype.fluid_usage_per_tick * 60
      calc_util.add_rate(rates.inputs, "fluid", fluid_name, prototypes.fluid[fluid_name].localised_name, fluid_usage)
    end
  end
end

