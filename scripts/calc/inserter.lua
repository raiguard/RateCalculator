-- Copied from https://mods.factorio.com/mod/inserter-throughput, under the Unlicense

local abs = math.abs
local sqrt = math.sqrt
local acos = math.acos
local round_up = math.ceil
local full_circle_in_radians = math.pi * 2

-- Belt speed in tiles per tick
-- Inserters can put items in the vicinity of their drop spot,
-- As long as there is no item center directly beneath them
-- E.g. they can place the second item on the very next tick
-- Also, the inserter can put down an item either before or after
-- The belt moves in a given tick (usually before)
-- Picking items up is vastly more complex and therefore not implemented
local function get_belt_penalty(belt_speed, stack_size)
  local penalty = 0
  stack_size = stack_size - 1
  local item_center_offset = belt_speed
  local acted = true
  while stack_size > 0 do
    if item_center_offset > 0 then
      stack_size = stack_size - 1
      item_center_offset = item_center_offset - 0.25 -- One item is 0.25 tiles long
      acted = true
    end
    item_center_offset = item_center_offset + belt_speed
    if not acted and (item_center_offset > 0) then
      stack_size = stack_size - 1
      item_center_offset = item_center_offset - 0.25 -- One item is 0.25 tiles long
      acted = true
    end
    penalty = penalty + 1
    acted = false
  end
  return penalty
end

local function calc(
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
  -- Get angle from the dot product
  local angle = acos((pickup_x * drop_x + pickup_y * drop_y) / (pickup_length * drop_length))
  -- Rotation speed is in full circles per tick
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

return calc
