local calc_util = require("scripts.calc.util")

return function(rates, entity, emissions_per_second, prototypes)
  local entity_prototype = entity.prototype
  for _, fluidbox in ipairs(entity_prototype.fluidbox_prototypes) do
    local filter = fluidbox.filter
    if filter then
      local fluid_name = filter.name
      local fluid_usage = entity_prototype.fluid_usage_per_tick * 60
      calc_util.add_rate(
        rates.materials,
        "input",
        "fluid",
        fluid_name,
        prototypes.fluid[fluid_name].localised_name,
        fluid_usage
      )
    end
  end

  return emissions_per_second
end

