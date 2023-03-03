local flib_bounding_box = require("__flib__/bounding-box")
local flib_math = require("__flib__/math")

local calc_util = {}

--- @param set MeasureRates
--- @param source MeasureSource
--- @param type string
--- @param name string
--- @param category string
--- @param amount double
--- @param invert boolean
function calc_util.add_rate(set, source, type, name, category, amount, invert)
  local path = type .. "/" .. name
  local source_rates = set[source]
  if not source_rates then
    source_rates = {}
    set[source] = source_rates
  end
  local rates = source_rates[path]
  if not rates then
    rates = {
      type = type,
      name = name,
      output = 0,
      input = 0,
      output_machines = 0,
      input_machines = 0,
    }
    source_rates[path] = rates
  end
  if invert then
    amount = amount * -1
  end
  rates[category] = math.max(rates[category] + amount, 0)
  rates[category .. "_machines"] = rates[category .. "_machines"] + (invert and -1 or 1)

  -- TODO: Find a better way to do this
  if flib_math.round(rates.input, 0.00001) == 0 and flib_math.round(rates.output, 0.00001) == 0 then
    set[path] = nil
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

--- @alias Measure
--- | "per-second",
--- | "per-minute",
--- | "per-hour",
--- | "transport-belts",
--- | "inserters",
--- | "power",
--- | "heat",

--- @param rates MeasureRates
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_crafter(rates, entity, invert)
  local recipe = entity.get_recipe()
  if not recipe and entity.type == "furnace" then
    recipe = entity.previous_recipe
  end
  if not recipe then
    return
  end

  -- The game engine has a hard limit of one craft per tick, or 60 crafts per second
  local crafts_per_second = math.min(entity.crafting_speed / recipe.energy, 60)
  -- Rocket silos will lose time to the launch animation
  if entity.type == "rocket-silo" then
    crafts_per_second = calc_util.get_rocket_adjusted_crafts_per_second(entity, crafts_per_second)
  end

  for _, ingredient in pairs(recipe.ingredients) do
    local amount = ingredient.amount * crafts_per_second
    calc_util.add_rate(rates, "materials", ingredient.type, ingredient.name, "input", amount, invert)
  end

  local productivity = entity.productivity_bonus + 1

  for _, product in pairs(recipe.products) do
    local adjusted_crafts_per_second = crafts_per_second * (product.probability or 1)

    -- Take the average amount if there is a min and max
    local amount = product.amount or (product.amount_max - ((product.amount_max - product.amount_min) / 2))
    local catalyst_amount = product.catalyst_amount or 0

    -- Catalysts are not affected by productivity
    local amount = (catalyst_amount + ((amount - catalyst_amount) * productivity)) * adjusted_crafts_per_second

    calc_util.add_rate(rates, "materials", product.type, product.name, "output", amount, invert)
  end
end

--- @param rates MeasureRates
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_electric_energy_source(rates, entity, invert)
  local entity_prototype = entity.prototype

  -- Electric energy interfaces can have their settings adjusted at runtime, so checking the energy source is pointless
  -- They also don't produce pollution whatsoever, despite their energy source emissions setting
  if entity.type == "electric-energy-interface" then
    local production = entity.power_production
    local usage = entity.power_usage

    local entity_name = entity.name

    if production > 0 then
      calc_util.add_rate(rates, "power", "entity", entity_name, "output", production, invert)
    end
    if usage > 0 then
      calc_util.add_rate(rates, "power", "entity", entity_name, "input", usage, invert)
    end
  else
    local electric_energy_source_prototype = entity_prototype.electric_energy_source_prototype

    local max_energy_usage = entity_prototype.max_energy_usage or 0
    if electric_energy_source_prototype and max_energy_usage > 0 then
      local consumption_bonus = (entity.consumption_bonus + 1)
      local drain = electric_energy_source_prototype.drain
      local amount = max_energy_usage * consumption_bonus
      if max_energy_usage ~= drain then
        amount = amount + drain
      end
      calc_util.add_rate(rates, "power", "entity", entity.name, "input", amount, invert)
    end

    local max_energy_production = entity_prototype.max_energy_production
    if max_energy_production > 0 then
      if entity.type == "solar-panel" then
        max_energy_production = max_energy_production * entity.surface.solar_power_multiplier
      end
      calc_util.add_rate(rates, "power", "entity", entity.name, "output", max_energy_production, invert)
      -- Pollution is not calculated here because the rate depends on entity-specific variables
    end
  end
end

--- @param rates MeasureRates
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_heat_energy_source(rates, entity, invert)
  calc_util.add_rate(
    rates,
    "heat",
    "entity",
    entity.name,
    "input",
    entity.prototype.max_energy_usage * (1 + entity.consumption_bonus),
    invert
  )
end

--- @class ResourceData
--- @field occurrences uint
--- @field products Product[]
--- @field required_fluid Product?
--- @field mining_time double

--- @param rates MeasureRates
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_mining_drill(rates, entity, invert)
  local entity_prototype = entity.prototype
  local entity_productivity_bonus = entity.productivity_bonus
  local entity_speed_bonus = entity.speed_bonus

  -- Look for resource entities under the drill
  local radius = entity_prototype.mining_drill_radius + 0.01
  local box = flib_bounding_box.from_dimensions(entity.position, radius * 2, radius * 2)
  local resource_entities = entity.surface.find_entities_filtered({ area = box })
  local resource_entities_len = #resource_entities
  if resource_entities_len == 0 then
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
      calc_util.add_rate(rates, "materials", "fluid", fluid_name, "input", fluid_per_second, invert)
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
      calc_util.add_rate(rates, "materials", product.type, product.name, "output", adjusted_product_per_second, invert)
    end
  end
end

--- @param rates MeasureRates
--- @param entity LuaEntity
--- @param invert boolean
function calc_util.process_reactor(rates, entity, invert)
  calc_util.add_rate(
    rates,
    "heat",
    "entity",
    entity.name,
    "output",
    entity.prototype.max_energy_usage * (entity.neighbour_bonus + 1),
    invert
  )
end

return calc_util
