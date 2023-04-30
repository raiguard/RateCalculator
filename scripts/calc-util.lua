local flib_bounding_box = require("__flib__/bounding-box")
local flib_table = require("__flib__/table")

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
--- @param amount double
--- @param invert boolean
--- @param machine_name string?
function calc_util.add_rate(set, category, type, name, amount, invert, machine_name)
  local set_rates = set.rates
  local path = type .. "/" .. name
  local rates = set_rates[path]
  if not rates then
    if invert then
      return -- Don't remove from rates that don't exist.
    end
    rates = {
      type = type,
      name = name,
      output = 0,
      input = 0,
      output_machines = 0,
      output_machine_counts = {},
      input_machines = 0,
      input_machine_counts = {},
    }
    set_rates[path] = rates
  end
  if invert then
    amount = amount * -1
  end
  if machine_name then
    local counts = rates[category .. "_machine_counts"]
    -- Don't remove a machine that doesn't exist
    if not counts[machine_name] and invert then
      goto no_rate
    end
    counts[machine_name] = (counts[machine_name] or 0) + (invert and -1 or 1)
    if counts[machine_name] == 0 then
      counts[machine_name] = nil
    end
  end
  rates[category] = math.max(rates[category] + amount, 0)
  rates[category .. "_machines"] = rates[category .. "_machines"] + (invert and -1 or 1)
  -- Account for floating-point imprecision
  if rates[category] < 0.00001 then
    rates[category] = 0
  end

  ::no_rate::
  if rates.input_machines == 0 and rates.output_machines == 0 then
    set_rates[path] = nil
  end
end

--- Source: https://github.com/ClaudeMetz/FactoryPlanner/blob/0f0aeae03386f78290d932cf51130bbcb2afa83d/modfiles/data/handlers/generator_util.lua#L364
--- @param prototype LuaEntityPrototype
--- @return number?
function calc_util.get_seconds_per_rocket_launch(prototype)
  local rocket_prototype = prototype.rocket_entity_prototype
  if not rocket_prototype then
    return nil
  end

  local rocket_flight_threshold = 0.5 -- hardcoded in the game files
  local launch_steps = {
    lights_blinking_open = (1 / prototype.light_blinking_speed) + 1,
    doors_opening = (1 / prototype.door_opening_speed) + 1,
    doors_opened = prototype.rocket_rising_delay + 1,
    rocket_rising = (1 / rocket_prototype.rising_speed) + 1,
    rocket_ready = 14, -- estimate for satellite insertion delay
    launch_started = prototype.launch_wait_time + 1,
    engine_starting = (1 / rocket_prototype.engine_starting_speed) + 1,
    -- This calculates a fractional amount of ticks. Also, math.log(x) calculates the natural logarithm
    rocket_flying = math.log(
      1 + rocket_flight_threshold * rocket_prototype.flying_acceleration / rocket_prototype.flying_speed
    ) / math.log(1 + rocket_prototype.flying_acceleration),
    lights_blinking_close = (1 / prototype.light_blinking_speed) + 1,
    doors_closing = (1 / prototype.door_opening_speed) + 1,
  }

  local total_ticks = 0
  for _, ticks_taken in pairs(launch_steps) do
    total_ticks = total_ticks + ticks_taken
  end

  return (total_ticks / 60) -- retured value is in seconds
end

--- @param entity LuaEntity
--- @param crafts_per_second double
--- @return double
function calc_util.get_rocket_adjusted_crafts_per_second(entity, crafts_per_second)
  local prototype = entity.prototype
  local seconds_per_launch = calc_util.get_seconds_per_rocket_launch(prototype)
  local normal_crafts = prototype.rocket_parts_required
  local missed_crafts = seconds_per_launch * crafts_per_second * (entity.productivity_bonus + 1)
  local ratio = normal_crafts / (normal_crafts + missed_crafts)
  return crafts_per_second * ratio
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_burner(set, entity, invert)
  local entity_prototype = entity.prototype
  local burner_prototype = entity_prototype.burner_prototype --[[@as LuaBurnerPrototype]]
  local burner = entity.burner --[[@as LuaBurner]]

  local currently_burning = burner.currently_burning
  if not currently_burning then
    local item_name = next(burner.inventory.get_contents())
    if item_name then
      currently_burning = game.item_prototypes[item_name]
    end
  end
  if not currently_burning then
    calc_util.add_error(set, "no-fuel")
    return
  end

  local max_energy_usage = entity_prototype.max_energy_usage * (entity.consumption_bonus + 1)
  local burns_per_second = 1 / (currently_burning.fuel_value / (max_energy_usage / burner_prototype.effectivity) / 60)

  calc_util.add_rate(set, "input", "item", currently_burning.name, burns_per_second, invert, entity.name)

  local burnt_result = currently_burning.burnt_result
  if burnt_result then
    calc_util.add_rate(set, "output", "item", burnt_result.name, burns_per_second, invert, entity.name)
  end
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
    return game.fluid_prototypes[fluid.name]
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
  local fluid_usage = entity_prototype.max_energy_usage / energy_per_amount * 60
  calc_util.add_rate(set, "input", "fluid", input_fluid.name, fluid_usage, invert, entity.name)

  local output_fluid = get_fluid(fluidbox, 2)
  if not output_fluid then
    return
  end

  calc_util.add_rate(set, "output", "fluid", output_fluid.name, fluid_usage, invert, entity.name)
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_crafter(set, entity, invert)
  local recipe = entity.get_recipe()
  if not recipe and entity.type == "furnace" then
    recipe = entity.previous_recipe
  end
  if not recipe then
    calc_util.add_error(set, "no-recipe")
    return
  end

  local crafts_per_second = entity.crafting_speed / recipe.energy
  -- The game engine has a hard limit of one craft per tick, or 60 crafts per second
  if crafts_per_second > 60 then
    crafts_per_second = 60
    calc_util.add_error(set, "max-crafting-speed")
  end
  -- Rocket silos will lose time to the launch animation
  if entity.type == "rocket-silo" then
    crafts_per_second = calc_util.get_rocket_adjusted_crafts_per_second(entity, crafts_per_second)
  end

  for _, ingredient in pairs(recipe.ingredients) do
    local amount = ingredient.amount * crafts_per_second
    calc_util.add_rate(set, "input", ingredient.type, ingredient.name, amount, invert, entity.name)
  end

  local productivity = entity.productivity_bonus + 1

  for _, product in pairs(recipe.products) do
    local adjusted_crafts_per_second = crafts_per_second * (product.probability or 1)

    -- Take the average amount if there is a min and max
    local amount = product.amount or (product.amount_max - ((product.amount_max - product.amount_min) / 2))
    local catalyst_amount = product.catalyst_amount or 0

    -- Catalysts are not affected by productivity
    local amount = (catalyst_amount + ((amount - catalyst_amount) * productivity)) * adjusted_crafts_per_second

    calc_util.add_rate(set, "output", product.type, product.name, amount, invert, entity.name)
  end
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_electric_energy_source(set, entity, invert)
  local entity_prototype = entity.prototype

  -- Electric energy interfaces can have their settings adjusted at runtime, so checking the energy source is pointless.
  if entity.type == "electric-energy-interface" then
    local production = entity.power_production * 60
    if production > 0 then
      calc_util.add_rate(set, "output", "item", "rcalc-power-dummy", production, invert, entity.name)
    end
    local usage = entity.power_usage * 60
    if usage > 0 then
      calc_util.add_rate(set, "input", "item", "rcalc-power-dummy", usage, invert, entity.name)
    end
    return
  end

  local electric_energy_source_prototype = entity_prototype.electric_energy_source_prototype --[[@as LuaElectricEnergySourcePrototype]]

  local max_energy_usage = entity_prototype.max_energy_usage or 0
  if max_energy_usage > 0 then
    local consumption_bonus = (entity.consumption_bonus + 1)
    local drain = electric_energy_source_prototype.drain
    local amount = max_energy_usage * consumption_bonus
    if max_energy_usage ~= drain then
      amount = amount + drain
    end
    calc_util.add_rate(set, "input", "item", "rcalc-power-dummy", amount * 60, invert, entity.name)
    if entity.status == defines.entity_status.no_power then
      calc_util.add_error(set, "no-power")
    end
  end

  local max_energy_production = entity_prototype.max_energy_production
  if max_energy_production > 0 then
    if entity.type == "solar-panel" then
      max_energy_production = max_energy_production * entity.surface.solar_power_multiplier
    end
    calc_util.add_rate(set, "output", "item", "rcalc-power-dummy", max_energy_production * 60, invert, entity.name)
  end
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_fluid_energy_source(set, entity, invert)
  --- @type LuaEntityPrototype
  local entity_prototype = entity.prototype
  local fluid_energy_source_prototype = entity_prototype.fluid_energy_source_prototype --[[@as LuaFluidEnergySourcePrototype]]
  local max_fluid_usage = fluid_energy_source_prototype.fluid_usage_per_tick

  -- The fluid energy source fluidbox will always be the last one
  local fluidbox = entity.fluidbox
  local fluid = fluidbox[#fluidbox]
  if not fluid then
    calc_util.add_error(set, "no-input-fluid")
    return
  end
  local max_energy_usage = entity_prototype.max_energy_usage * (entity.consumption_bonus + 1)
  local fluid_prototype = game.fluid_prototypes[fluid.name]

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
  if not value then
    return -- No error, but not rate either
  end

  calc_util.add_rate(set, "input", "fluid", fluid.name, value, invert, entity.name)
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
  calc_util.add_rate(set, "input", "fluid", fluid.name, entity_prototype.fluid_usage_per_tick * 60, invert, entity.name)
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
    entity.prototype.max_energy_usage * (1 + entity.consumption_bonus) * 60,
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
  local researching_speed = entity.prototype.researching_speed
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
    local amount = ((ingredient.amount * lab_multiplier) / game.item_prototypes[ingredient.name].durability)
    calc_util.add_rate(set, "input", "item", ingredient.name, amount, invert, entity.name)
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
        name = required_fluid,
        amount = mineable_properties.fluid_amount / 10, -- Ten mining operations per fluid consumed
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
      calc_util.add_rate(set, "input", "fluid", fluid_name, fluid_per_second, invert, entity.name)
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
      calc_util.add_rate(set, "output", product.type, product.name, adjusted_product_per_second, invert, entity.name)
    end
  end
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_offshore_pump(set, entity, invert)
  local entity_prototype = entity.prototype
  local fluid_prototype = entity_prototype.fluid --[[@as LuaFluidPrototype]]
  calc_util.add_rate(
    set,
    "output",
    "fluid",
    fluid_prototype.name,
    entity_prototype.pumping_speed * 60,
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
    entity.prototype.max_energy_usage * (1 + entity.neighbour_bonus) * (1 + entity.consumption_bonus) * 60,
    invert,
    entity.name
  )
end

return calc_util
