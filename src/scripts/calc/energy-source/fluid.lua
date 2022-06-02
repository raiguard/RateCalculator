local calc_util = require("scripts.calc.util")

return function(rates, entity, emissions_per_second, prototypes)
  --- @type LuaEntityPrototype
  local entity_prototype = entity.prototype
  local fluid_energy_source_prototype = entity_prototype.fluid_energy_source_prototype

  local max_fluid_usage = fluid_energy_source_prototype.fluid_usage_per_tick

  -- The fluid energy source fluidbox will always be the last one
  local fluidbox = entity.fluidbox
  local fluid = fluidbox[#fluidbox]
  if fluid then
    local max_energy_usage = entity_prototype.max_energy_usage * (entity.consumption_bonus + 1)
    --- @type LuaFluidPrototype
    local fluid_prototype = prototypes.fluid[fluid.name]

    local value
    if fluid_energy_source_prototype.scale_fluid_usage then
      if fluid_energy_source_prototype.burns_fluid and fluid_prototype.fuel_value > 0 then
        local fluid_usage_now = max_energy_usage / (fluid_prototype.fuel_value / 60)
        if max_fluid_usage > 0 then
          value = math.min(fluid_usage_now, max_fluid_usage)
        else
          value = fluid_usage_now
        end
      else
        -- If the fluid is equal to its default temperature, then nothing will happen
        local temperature_value = fluid.temperature - fluid_prototype.default_temperature
        if temperature_value > 0 then
          value = max_energy_usage / (temperature_value * fluid_prototype.heat_capacity) * 60
        end
      end
    else
      value = max_fluid_usage * 60
    end

    if value then
      calc_util.add_rate(
        rates,
        "input",
        "fluid",
        fluid.name,
        fluid_prototype.localised_name,
        value,
        "entity/" .. entity.name
      )

      return emissions_per_second + (fluid_energy_source_prototype.emissions * max_energy_usage * 60)
    end
  end

  return emissions_per_second
end
