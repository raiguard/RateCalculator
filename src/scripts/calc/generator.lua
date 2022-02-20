local calc_util = require("scripts.calc.util")

--- @param entity LuaEntity
return function(rates, entity, emissions_per_second, prototypes)
  local entity_prototype = entity.prototype
  local fluidbox = entity.fluidbox
  for i, fluidbox_prototype in ipairs(entity_prototype.fluidbox_prototypes) do
    local fluid
    if fluidbox_prototype.filter then
      fluid = fluidbox_prototype.filter.name
    elseif fluidbox[i] then
      fluid = fluidbox[i].name
    end
    if fluid then
      --- @type LuaFluidPrototype
      local fluid_prototype = prototypes.fluid[fluid]
      local fluid_usage = entity_prototype.fluid_usage_per_tick * 60
      calc_util.add_rate(rates.materials, "input", "fluid", fluid, fluid_prototype.localised_name, fluid_usage)

      local added_emissions = entity_prototype.electric_energy_source_prototype.emissions
        * entity_prototype.max_energy_production
        * 60
        * fluid_prototype.emissions_multiplier
      emissions_per_second = emissions_per_second + added_emissions
    end
  end

  return emissions_per_second
end
