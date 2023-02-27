local flib_math = require("__flib__/math")

local calc_util = {}

--- @param set CalculationSet
--- @param type string
--- @param name string
--- @param category string
--- @param amount double
--- @param invert boolean
function calc_util.add_rate(set, type, name, category, amount, invert)
  local path = type .. "/" .. name
  local rates = set[path]
  if not rates then
    rates = {
      type = type,
      name = name,
      output = 0,
      input = 0,
      entities = 0,
    }
    set[path] = rates
  end
  rates.entities = rates.entities + 1
  if invert then
    amount = amount * -1
  end
  rates[category] = math.max(rates[category] + amount, 0)

  if flib_math.round(rates.input, 0.01) == 0 and flib_math.round(rates.output, 0.01) == 0 then
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

return calc_util
