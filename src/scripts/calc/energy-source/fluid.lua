local calc_util = require("scripts.calc.util")

-- TODO: some things don't scale fluid usage with power!
return function(rates, entity, prototypes, emissions_per_second)
  local entity_prototype = entity.prototype
  local fluid_energy_source_prototype = entity_prototype.fluid_energy_source_prototype

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

      return emissions_per_second + (
        fluid_energy_source_prototype.emissions
        * 60
        * max_energy_usage
        * fluid_prototype.emissions_multiplier
      )
    end
  end

  return emissions_per_second
end