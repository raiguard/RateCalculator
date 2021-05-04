-- Adapted from https://mods.factorio.com/mod/inserter-throughput, under the Unlicense

local abs = math.abs
local sqrt = math.sqrt
local acos = math.acos
local round_up = math.ceil
local full_circle_in_radians = math.pi * 2

-- belt speed in tiles per tick
-- inserters can put items in the vicinity of their drop spot,
-- as long as there is no item center directly beneath them
-- e.g. they can place the second item on the very next tick
-- also, the inserter can put down an item either before or after
-- the belt moves in a given tick (usually before)
-- picking items up is vastly more complex and therefore not implemented
local function get_belt_penalty(belt_speed, stack_size)
  local penalty = 0
  stack_size = stack_size - 1
  local item_center_offset = belt_speed
  local acted = true
  while stack_size > 0 do
    if item_center_offset > 0 then
      stack_size = stack_size - 1
      item_center_offset = item_center_offset - 0.25 -- one item is 0.25 tiles long
      acted = true
    end
    item_center_offset = item_center_offset + belt_speed
    if not acted and (item_center_offset > 0) then
      stack_size = stack_size - 1
      item_center_offset = item_center_offset - 0.25 -- one item is 0.25 tiles long
      acted = true
    end
    penalty = penalty + 1
    acted = false
    end
  return penalty
end

local function calc_internal(
  rotation_speed,
  extension_speed,
  pickup_vector,
  drop_vector,
  stack_size,
  pickup_belt_speed,
  drop_belt_speed
)
  local pickup_x, pickup_y, drop_x, drop_y = pickup_vector[1], pickup_vector[2], drop_vector[1], drop_vector[2]
  local pickup_length = sqrt(pickup_x * pickup_x + pickup_y * pickup_y)
  local drop_length = sqrt(drop_x * drop_x + drop_y * drop_y)
  -- get angle from the dot product
  local angle = acos((pickup_x * drop_x + pickup_y * drop_y) / (pickup_length * drop_length))
  -- rotation speed is in full circles per tick
  local ticks_per_cycle = 2 * round_up(angle / full_circle_in_radians / rotation_speed)
  local extension_time = 2 * round_up(abs(pickup_length - drop_length) / extension_speed)
  if ticks_per_cycle < extension_time then
    ticks_per_cycle = extension_time
  end
  if (pickup_belt_speed > 0) and (stack_size > 1) then
    ticks_per_cycle = ticks_per_cycle + get_belt_penalty(pickup_belt_speed, stack_size)
  end
  if (drop_belt_speed > 0) and (stack_size > 1) then
    ticks_per_cycle = ticks_per_cycle + get_belt_penalty(drop_belt_speed, stack_size)
  end
  return stack_size * 60 / ticks_per_cycle -- 60 = ticks per second
end

local function vector(from, to)
  return {to.x - from.x, to.y - from.y}
end

local function calc(inserter)
  local inserter_position = inserter.position
  local prototype = inserter.type == "entity-ghost" and inserter.ghost_prototype or inserter.prototype
  local stack_size = inserter.inserter_stack_size_override
  if stack_size == 0 then
    local force = inserter.force
    if prototype.stack then
      stack_size = 1 + force.stack_inserter_capacity_bonus
    else
      stack_size = 1 + force.inserter_stack_size_bonus
    end
  end

  local pickup_position = inserter.pickup_position
  local pickup_target = inserter.pickup_target
  local pickup_belt_speed = 0
  if not pickup_target then
    pickup_target = inserter.surface.find_entities_filtered{
      position = pickup_position}[1]
  end
  if pickup_target then
    if pickup_target.type == "entity-ghost" then
      pickup_belt_speed = pickup_target.ghost_prototype.belt_speed or 0
    else
      pickup_belt_speed = pickup_target.prototype.belt_speed or 0
    end
  end

  local drop_position = inserter.drop_position
  local drop_target = inserter.drop_target
  local drop_belt_speed = 0
  if not drop_target then
    drop_target = inserter.surface.find_entities_filtered{
      position = drop_position}[1]
  end
  if drop_target then
    if drop_target.type == "entity-ghost" then
      drop_belt_speed = drop_target.ghost_prototype.belt_speed or 0
    else
      drop_belt_speed = drop_target.prototype.belt_speed or 0
    end
  end

  local value = calc_internal(
    prototype.inserter_rotation_speed,
    prototype.inserter_extension_speed,
    vector(inserter_position, pickup_position),
    vector(inserter_position, drop_position),
    stack_size,
    pickup_belt_speed,
    drop_belt_speed
  )

  return value
end

return calc

