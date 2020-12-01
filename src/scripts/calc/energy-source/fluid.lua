local calc_util = require("scripts.calc.util")

return function(rates, entity, prototypes)
  local entity_prototype = entity.prototype

  local fluid_energy_source_prototype = entity_prototype.fluid_energy_source_prototype
  if fluid_energy_source_prototype then
    -- the fluid energy source fluidbox will always be the last one
    local fluidbox = entity.fluidbox[#entity.fluidbox]
    if fluidbox then
      local max_energy_usage = entity_prototype.max_energy_usage
      local fluid_prototype = prototypes.fluid[fluidbox.name]
      if fluid_prototype.fuel_value then
        local value = max_energy_usage / (fluid_prototype.fuel_value / 60) / 60
        calc_util.add_rate(
          rates.inputs,
          "fluid",
          fluidbox.name,
          fluid_prototype.localised_name,
          value
        )
      end
    end
  end
end