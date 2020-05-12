local constants = {}

local crafter_types = {
  "assembling-machine",
  "furnace",
  "rocket-silo"
}

local crafter_type_lookup = {}

for i = 1, #crafter_types do
  crafter_type_lookup[crafter_types[i]] = true
end

constants.crafter_types = crafter_types
constants.crafter_type_lookup = crafter_type_lookup

return constants

--[[

-- custom create_from_center function, omitting ensure_xy and using the radius instead of the width
local function create_from_center(position, radius)
  return {
    left_top = {x=position.x-radius, y=position.y-radius},
    right_bottom = {x=position.x+radius, y=position.y+radius}
  }
end

-- custom collides function, omitting ensure_xy since those are already gauranteed
local function collides_with(box1, box2)
  return box1.left_top.x < box2.right_bottom.x and
    box2.left_top.x < box1.right_bottom.x and
    box1.left_top.y < box2.right_bottom.y and
    box2.left_top.y < box1.right_bottom.y
end

]]