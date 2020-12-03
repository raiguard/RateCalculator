local calc_util = require("scripts.calc.util")

return function(rates, entity, prototypes, emissions_per_second)
  local entity_prototype = entity.prototype
  local fluid_energy_source_prototype = entity_prototype.fluid_energy_source_prototype

  local max_fluid_usage = fluid_energy_source_prototype.fluid_usage_per_tick

  -- the fluid energy source fluidbox will always be the last one
  local fluidbox = entity.fluidbox
  local fluid = fluidbox[#fluidbox]
  if fluid then
    local max_energy_usage = entity_prototype.max_energy_usage * (entity.consumption_bonus + 1)
    local fluid_prototype = prototypes.fluid[fluid.name]

    local value
    if fluid_energy_source_prototype.scale_fluid_usage then
      if fluid_energy_source_prototype.burns_fluid and fluid_prototype.fuel_value > 0 then
        value = math.min(max_energy_usage / (fluid_prototype.fuel_value / 60), max_fluid_usage)
      else
        value = (
          (
            max_energy_usage
            / ((fluid.temperature - fluid_prototype.default_temperature) * fluid_prototype.heat_capacity)
          )
          * 60
        )
      end
    else
      value = max_fluid_usage * 60
    end

    if value then
      calc_util.add_rate(
        rates.inputs,
        "fluid",
        fluid.name,
        fluid_prototype.localised_name,
        value
      )

      return emissions_per_second + (fluid_energy_source_prototype.emissions * max_energy_usage * 60)
    end
  end

  return emissions_per_second
end