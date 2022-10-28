local calc_util = require("__RateCalculator__.scripts.calc.util")

--- @param fluidbox LuaFluidBox
--- @param index uint
--- @return LuaFluidPrototype?
local function get_fluid(fluidbox, index)
  local fluid = fluidbox.get_filter(index)
  if not fluid then
    fluid = fluidbox[index] --[[@as FluidBoxFilter?]]
  end
  if fluid then
    return game.fluid_prototypes[fluid.name]
  end
end

--- @param entity LuaEntity
return function(rates, entity, emissions_per_second)
  local entity_prototype = entity.prototype
  local fluidbox = entity.fluidbox

  local input_fluid = get_fluid(fluidbox, 1)
  if input_fluid then
    local minimum_temperature = fluidbox.get_prototype(1).minimum_temperature or input_fluid.default_temperature
    local energy_per_amount = (entity_prototype.target_temperature - minimum_temperature) * input_fluid.heat_capacity
    local fluid_usage = entity_prototype.max_energy_usage / energy_per_amount * 60
    calc_util.add_rate(
      rates.materials,
      "input",
      "fluid",
      input_fluid.name,
      input_fluid.localised_name,
      fluid_usage,
      "entity/" .. entity.name
    )

    local output_fluid = get_fluid(fluidbox, 2)
    if output_fluid then
      calc_util.add_rate(
        rates.materials,
        "output",
        "fluid",
        output_fluid.name,
        output_fluid.localised_name,
        fluid_usage,
        "entity/" .. entity.name
      )
    end
  end

  return emissions_per_second
end
