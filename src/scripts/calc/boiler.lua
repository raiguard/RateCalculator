local calc_util = require("scripts.calc.util")

local function calc_fluidbox_rate(entity_prototype, fluid_prototype)
  local energy_per_amount =
    (entity_prototype.target_temperature - fluid_prototype.default_temperature) * fluid_prototype.heat_capacity
  local max_consumption = entity_prototype.max_energy_usage / energy_per_amount
  return max_consumption * 60
end

return function(rates, entity, emissions_per_second, prototypes)
  local entity_prototype = entity.prototype

  for i, rate_kind in ipairs{"input", "output"} do
    local fluid = entity.fluidbox.get_filter(i)
    if fluid then
      local fluid_prototype = prototypes.fluid[fluid.name]
      calc_util.add_rate(
        rates.materials,
        rate_kind,
        "fluid",
        fluid.name,
        fluid_prototype.localised_name,
        calc_fluidbox_rate(entity_prototype, fluid_prototype)
      )
    end
  end

  return emissions_per_second
end
