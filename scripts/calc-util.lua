local flib_bounding_box = require("__flib__.bounding-box")
local flib_math = require("__flib__.math")
local flib_table = require("__flib__.table")

--- @alias RateCategory
--- | "output"
--- | "input"

--- @class ResourceData
--- @field occurrences uint
--- @field products Product[]
--- @field required_fluid Product?
--- @field mining_time double

--- @alias Timescale
--- | "per-second",
--- | "per-minute",
--- | "per-hour",
--- | "transport-belts",
--- | "inserters",

--- @class CalcUtil
local calc_util = {}

--- @param set CalculationSet
--- @param error CalculationError
function calc_util.add_error(set, error)
  set.errors[error] = true
end

--- @param set CalculationSet
--- @param category RateCategory
--- @param type string
--- @param name string
--- @param quality string
--- @param amount double
--- @param invert boolean
--- @param machine_name string?
--- @param temperature double?
function calc_util.add_rate(set, category, type, name, quality, amount, invert, machine_name, temperature)
  local set_rates = set.rates
  local path = type .. "/" .. name .. "/" .. quality .. (temperature or "")
  local rates = set_rates[path]
  if not rates then
    if invert then
      return -- Don't remove from rates that don't exist.
    end
    --- @type Rates
    rates = {
      type = type,
      name = name,
      quality = quality,
      temperature = temperature,
      output = { machines = 0, machine_counts = {}, rate = 0 },
      input = { machines = 0, machine_counts = {}, rate = 0 },
    }
    set_rates[path] = rates
  end
  if invert then
    amount = -amount
  end
  --- @type Rate
  local rate = rates[category]
  if machine_name then
    local counts = rate.machine_counts
    -- Don't remove a machine that doesn't exist
    if not counts[machine_name] and invert then
      goto no_rate
    end
    counts[machine_name] = (counts[machine_name] or 0) + (invert and -1 or 1)
    if counts[machine_name] == 0 then
      counts[machine_name] = nil
    end
  end
  rate.rate = math.max(rate.rate + amount, 0)
  rate.machines = rate.machines + (invert and -1 or 1)
  -- Account for floating-point imprecision
  if rate.rate < 0.00001 then
    rate.rate = 0
  end

  ::no_rate::
  if rates.input.machines == 0 and rates.output.machines == 0 then
    set_rates[path] = nil
  end
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
--- @param emissions_per_second double
--- @return double
function calc_util.process_burner(set, entity, invert, emissions_per_second)
  local entity_prototype = entity.prototype
  local burner_prototype = entity_prototype.burner_prototype --[[@as LuaBurnerPrototype]]
  local burner = entity.burner --[[@as LuaBurner]]

  local currently_burning = burner.currently_burning
  if not currently_burning then
    local item = burner.inventory.get_contents()[1]
    if item then
      currently_burning = { name = prototypes.item[item.name], quality = prototypes.quality[item.quality] }
    end
  end
  if not currently_burning then
    calc_util.add_error(set, "no-fuel")
    return emissions_per_second
  end

  local currently_burning_prototype = currently_burning.name

  local max_energy_usage = entity_prototype.get_max_energy_usage(entity.quality) * (entity.consumption_bonus + 1)
  local burns_per_second = 1
    / (currently_burning_prototype.fuel_value / (max_energy_usage / burner_prototype.effectivity) / 60)

  calc_util.add_rate(
    set,
    "input",
    "item",
    currently_burning_prototype.name,
    currently_burning.quality.name,
    burns_per_second,
    invert,
    entity.name
  )

  local burnt_result = currently_burning_prototype.burnt_result
  if burnt_result then
    calc_util.add_rate(
      set,
      "output",
      "item",
      burnt_result.name,
      currently_burning.quality.name,
      burns_per_second,
      invert,
      entity.name
    )
  end

  local emissions = (burner_prototype.emissions_per_joule[set.pollutant] or 0)
    * 60
    * max_energy_usage
    * currently_burning_prototype.fuel_emissions_multiplier
  return emissions_per_second + emissions
end

--- @param fluidbox LuaFluidBox
--- @param index uint
--- @return LuaFluidPrototype?
local function get_fluid(fluidbox, index)
  local fluid = fluidbox.get_filter(index)
  if not fluid then
    fluid = fluidbox[index] --[[@as FluidBoxFilter?]]
  end
  if fluid then
    return prototypes.fluid[fluid.name]
  end
end

--- @param set CalculationSet
--- @param entity LuaEntity
function calc_util.process_beacon(set, entity)
  if entity.status == defines.entity_status.no_power then
    calc_util.add_error(set, "no-power")
  end
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_boiler(set, entity, invert)
  local entity_prototype = entity.prototype
  local fluidbox = entity.fluidbox

  local input_fluid = get_fluid(fluidbox, 1)
  if not input_fluid then
    calc_util.add_error(set, "no-input-fluid")
    return
  end

  local minimum_temperature = fluidbox.get_prototype(1).minimum_temperature or input_fluid.default_temperature
  local energy_per_amount = (entity_prototype.target_temperature - minimum_temperature) * input_fluid.heat_capacity
  local fluid_usage = entity_prototype.get_max_energy_usage(entity.quality) / energy_per_amount * 60
  calc_util.add_rate(set, "input", "fluid", input_fluid.name, "normal", fluid_usage, invert, entity.name)

  if entity_prototype.boiler_mode == "heat-water-inside" then
    calc_util.add_rate(
      set,
      "output",
      "fluid",
      input_fluid.name,
      "normal",
      fluid_usage,
      invert,
      entity.name,
      input_fluid.max_temperature
    )
    return
  end

  local output_fluid = get_fluid(fluidbox, 2)
  if not output_fluid then
    return
  end

  local minimum_temperature = fluidbox.get_prototype(2).minimum_temperature or output_fluid.default_temperature
  local energy_per_amount = (entity_prototype.target_temperature - minimum_temperature) * output_fluid.heat_capacity
  local fluid_usage = entity_prototype.get_max_energy_usage(entity.quality) / energy_per_amount * 60
  calc_util.add_rate(set, "output", "fluid", output_fluid.name, "normal", fluid_usage, invert, entity.name)
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
--- @return double
function calc_util.process_crafter(set, entity, invert, emissions_per_second)
  local recipe, quality = entity.get_recipe()
  if not recipe and entity.type == "furnace" then
    local prev = entity.previous_recipe
    if prev then
      recipe = set.player.force.recipes[prev.name.name]
      quality = prev.quality --[[@as LuaQualityPrototype]]
    end
  end
  if not recipe then
    calc_util.add_error(set, "no-recipe")
    return emissions_per_second
  end
  --- @cast quality -?

  local crafts_per_second = entity.crafting_speed / recipe.energy

  for _, ingredient in pairs(recipe.ingredients) do
    local amount = ingredient.amount * crafts_per_second
    calc_util.add_rate(
      set,
      "input",
      ingredient.type,
      ingredient.name,
      ingredient.type == "item" and quality.name or "normal",
      amount,
      invert,
      entity.name
    )
  end

  -- Total productivity is capped at +300%
  local productivity = math.min(entity.productivity_bonus + recipe.productivity_bonus + 1, 4)

  for _, product in pairs(recipe.products) do
    local adjusted_crafts_per_second = crafts_per_second * (product.probability or 1)

    -- Take the average amount if there is a min and max
    local amount = product.amount or (product.amount_max - ((product.amount_max - product.amount_min) / 2))
    local catalyst_amount = math.min(product.ignored_by_productivity or 0, amount)

    -- Catalysts are not affected by productivity
    local amount = (catalyst_amount + ((amount - catalyst_amount) * productivity)) * adjusted_crafts_per_second

    calc_util.add_rate(
      set,
      "output",
      product.type,
      product.name,
      product.type == "item" and quality.name or "normal",
      amount,
      invert,
      entity.name,
      product.temperature
    )
  end

  return emissions_per_second * recipe.prototype.emissions_multiplier * (1 + entity.pollution_bonus)
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
--- @param emissions_per_second double
--- @return double
function calc_util.process_electric_energy_source(set, entity, invert, emissions_per_second)
  local entity_prototype = entity.prototype

  -- Electric energy interfaces can have their settings adjusted at runtime, so checking the energy source is pointless.
  if entity.type == "electric-energy-interface" then
    local production = entity.power_production * 60
    if production > 0 then
      calc_util.add_rate(set, "output", "item", "rcalc-power-dummy", "normal", production, invert, entity.name)
    end
    local usage = entity.power_usage * 60
    if usage > 0 then
      calc_util.add_rate(set, "input", "item", "rcalc-power-dummy", "normal", usage, invert, entity.name)
    end
    return emissions_per_second
  end

  local electric_energy_source_prototype = entity_prototype.electric_energy_source_prototype --[[@as LuaElectricEnergySourcePrototype]]

  local added_emissions = 0
  local max_energy_usage = entity_prototype.get_max_energy_usage(entity.quality) or 0
  if max_energy_usage > 0 and max_energy_usage < flib_math.max_int53 then
    local consumption_bonus = (entity.consumption_bonus + 1)
    local drain = electric_energy_source_prototype.drain
    local amount = max_energy_usage * consumption_bonus
    if max_energy_usage ~= drain then
      amount = amount + drain
    end
    calc_util.add_rate(set, "input", "item", "rcalc-power-dummy", "normal", amount * 60, invert, entity.name)
    if entity.status == defines.entity_status.no_power then
      calc_util.add_error(set, "no-power")
    end
    -- TODO raiguard: Read which pollutant to use
    added_emissions = (electric_energy_source_prototype.emissions_per_joule[set.pollutant] or 0)
      * (max_energy_usage * consumption_bonus)
      * 60
  end

  local max_energy_production = entity_prototype.get_max_energy_production(entity.quality)
  if max_energy_production > 0 and max_energy_production < flib_math.max_int53 then
    if entity.type == "solar-panel" then
      max_energy_production = max_energy_production * entity.surface.solar_power_multiplier
    end
    calc_util.add_rate(
      set,
      "output",
      "item",
      "rcalc-power-dummy",
      "normal",
      max_energy_production * 60,
      invert,
      entity.name
    )
  end

  return emissions_per_second + added_emissions
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
--- @param emissions_per_second double
--- @return double
function calc_util.process_fluid_energy_source(set, entity, invert, emissions_per_second)
  --- @type LuaEntityPrototype
  local entity_prototype = entity.prototype
  local fluid_energy_source_prototype = entity_prototype.fluid_energy_source_prototype --[[@as LuaFluidEnergySourcePrototype]]

  local fluidbox = entity.fluidbox
  -- The fluid energy source fluidbox will always be the last one
  local fluid_prototype = get_fluid(fluidbox, #fluidbox)
  if not fluid_prototype then
    calc_util.add_error(set, "no-input-fluid")
    return emissions_per_second
  end
  local max_energy_usage = entity_prototype.get_max_energy_usage(entity.quality) * (entity.consumption_bonus + 1)

  local value
  if fluid_energy_source_prototype.scale_fluid_usage then
    if fluid_energy_source_prototype.burns_fluid and fluid_prototype.fuel_value > 0 then
      value = max_energy_usage / (fluid_prototype.fuel_value / 60) / fluid_energy_source_prototype.effectivity
    else
      -- Now we need the actual fluid to get its temperature
      local fluid = fluidbox[#fluidbox]
      if not fluid then
        calc_util.add_error(set, "no-input-fluid")
        return emissions_per_second
      end
      -- If the fluid is equal to its default temperature, then nothing will happen
      local temperature_value = fluid.temperature - fluid_prototype.default_temperature
      if temperature_value > 0 then
        value = max_energy_usage
          / (temperature_value * fluid_prototype.heat_capacity)
          / fluid_energy_source_prototype.effectivity
          * 60
      end
    end
  else
    value = fluid_energy_source_prototype.fluid_usage_per_tick / fluid_energy_source_prototype.effectivity * 60
  end
  if not value then
    return emissions_per_second -- No error, but not rate either
  end

  calc_util.add_rate(set, "input", "fluid", fluid_prototype.name, "normal", value, invert, entity.name)

  -- TODO raiguard: Detect pollutant of current surface
  return (fluid_energy_source_prototype.emissions_per_joule[set.pollutant] or 0) * max_energy_usage * 60
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_generator(set, entity, invert)
  local entity_prototype = entity.prototype
  local fluid = get_fluid(entity.fluidbox, 1)
  if not fluid then
    calc_util.add_error(set, "no-input-fluid")
    return
  end
  calc_util.add_rate(
    set,
    "input",
    "fluid",
    fluid.name,
    "normal",
    entity_prototype.fluid_usage_per_tick * 60,
    invert,
    entity.name
  )
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_heat_energy_source(set, entity, invert)
  calc_util.add_rate(
    set,
    "input",
    "item",
    "rcalc-heat-dummy",
    "normal",
    entity.prototype.get_max_energy_usage(entity.quality) * (1 + entity.consumption_bonus) * 60,
    invert,
    entity.name
  )
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_lab(set, entity, invert)
  local research_data = set.research_data
  if not research_data then
    calc_util.add_error(set, "no-active-research")
    return
  end

  local research_multiplier = research_data.multiplier
  local researching_speed = entity.prototype.get_researching_speed(entity.quality)
  local speed_modifier = research_data.speed_modifier
  -- XXX: Due to a bug with entity_speed_bonus, we must subtract the force's lab speed bonus and convert it to a
  -- multiplicative relationship
  local lab_multiplier = research_multiplier
    * ((entity.speed_bonus + 1 - speed_modifier) * (speed_modifier + 1))
    * researching_speed

  local inputs = flib_table.invert(entity.prototype.lab_inputs)
  for _, ingredient in pairs(research_data.ingredients) do
    if not inputs[ingredient.name] then
      calc_util.add_error(set, "incompatible-science-packs")
      return
    end
  end

  for _, ingredient in ipairs(research_data.ingredients) do
    -- TODO: Select quality
    local amount = (ingredient.amount * lab_multiplier) / prototypes.item[ingredient.name].get_durability()
    calc_util.add_rate(set, "input", "item", ingredient.name, "normal", amount, invert, entity.name)
  end
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_mining_drill(set, entity, invert)
  local entity_prototype = entity.prototype
  local entity_productivity_bonus = entity.productivity_bonus
  local entity_speed_bonus = entity.speed_bonus

  -- Look for resource entities under the drill
  local radius = entity_prototype.mining_drill_radius + 0.01
  local box = flib_bounding_box.from_dimensions(entity.position, radius * 2, radius * 2)
  local resource_entities = entity.surface.find_entities_filtered({ area = box })
  local resource_entities_len = #resource_entities
  if resource_entities_len == 0 then
    calc_util.add_error(set, "no-mineable-resources")
    return
  end

  --- @type table<string, ResourceData>
  local resources = {}
  local num_resource_entities = 0
  local has_fluidbox = next(entity_prototype.fluidbox_prototypes) and true or false
  local resource_categories = entity_prototype.resource_categories or {}
  for i = 1, resource_entities_len do
    local resource = resource_entities[i]
    local resource_name = resource.name

    -- If this resource has already been processed
    local resource_data = resources[resource_name]
    if resource_data then
      resource_data.occurrences = resource_data.occurrences + 1
      num_resource_entities = num_resource_entities + 1
      goto continue
    end

    local resource_prototype = resource.prototype
    if not resource_categories[resource_prototype.resource_category] then
      goto continue
    end
    num_resource_entities = num_resource_entities + 1
    local mineable_properties = resource_prototype.mineable_properties
    local required_fluid = mineable_properties.required_fluid
    if required_fluid and not has_fluidbox then
      goto continue
    end

    resource_data = {
      occurrences = 1,
      products = mineable_properties.products,
      mining_time = mineable_properties.mining_time,
    }

    if resource_prototype.infinite_resource then
      resource_data.mining_time = resource_data.mining_time
        / (resource.amount / resource_prototype.normal_resource_amount)
    end

    if required_fluid then
      resource_data.required_fluid = {
        type = "fluid",
        name = required_fluid,
        amount = mineable_properties.fluid_amount / 10, -- Ten mining operations per fluid consumed
        probability = 1,
      }
    end

    resources[resource_name] = resource_data

    ::continue::
  end

  if num_resource_entities == 0 then
    calc_util.add_error(set, "no-mineable-resources")
    return
  end

  -- Process resource entities

  local adjusted_mining_speed = entity_prototype.mining_speed
    * (entity_speed_bonus + 1)
    * (entity_productivity_bonus + 1)

  for _, resource_data in pairs(resources) do
    local resource_multiplier = (adjusted_mining_speed / resource_data.mining_time)
      * (resource_data.occurrences / num_resource_entities)

    -- Add required fluid to inputs
    local required_fluid = resource_data.required_fluid
    if required_fluid then
      -- Productivity does not apply to ingredients
      local fluid_per_second = required_fluid.amount * resource_multiplier / (entity_productivity_bonus + 1)

      -- Add to inputs table
      local fluid_name = required_fluid.name
      calc_util.add_rate(set, "input", "fluid", fluid_name, "normal", fluid_per_second, invert, entity.name)
    end

    -- Iterate each product
    for _, product in pairs(resource_data.products or {}) do
      -- Get rate per second for this product on this drill
      local product_per_second
      if product.amount then
        product_per_second = product.amount * resource_multiplier
      else
        product_per_second = product.amount_max - (product.amount_max - product.amount_min) / 2 * resource_multiplier
      end

      -- Account for probability
      local adjusted_product_per_second = product_per_second * (product.probability or 1)

      -- Add to outputs table
      calc_util.add_rate(
        set,
        "output",
        product.type,
        product.name,
        "normal",
        adjusted_product_per_second,
        invert,
        entity.name,
        product.temperature
      )
    end
  end
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_offshore_pump(set, entity, invert)
  local fluid = entity.fluidbox[1]
  if not fluid then
    return
  end
  calc_util.add_rate(
    set,
    "output",
    "fluid",
    fluid.name,
    "normal",
    entity.prototype.pumping_speed * 60,
    invert,
    entity.name
  )
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_reactor(set, entity, invert)
  calc_util.add_rate(
    set,
    "output",
    "item",
    "rcalc-heat-dummy",
    "normal",
    entity.prototype.get_max_energy_usage(entity.quality)
      * (1 + entity.neighbour_bonus)
      * (1 + entity.consumption_bonus)
      * 60,
    invert,
    entity.name
  )
end

return calc_util
