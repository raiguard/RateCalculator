local constants = {}

local crafter_types = {
  "assembling-machine",
  "furnace",
  -- "rocket-silo"
}

local crafter_type_lookup = {}

for i = 1, #crafter_types do
  crafter_type_lookup[crafter_types[i]] = true
end

constants.crafter_types = crafter_types
constants.crafter_type_lookup = crafter_type_lookup
constants.units_list = {
  {"rcalc-gui-units.materials-per-second"},
  {"rcalc-gui-units.materials-per-minute"},
  {"rcalc-gui-units.transport-belts"},
  {"rcalc-gui-units.inserters"},
  {"rcalc-gui-units.train-wagons-per-second"},
  {"rcalc-gui-units.train-wagons-per-minute"}
}

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

-- ! PROTOTYPE RENDERING
local box = entity.bounding_box
-- local width = box.right_bottom.x - box.left_top.x
-- local height = box.right_bottom.y - box.left_top.y
-- local background_scale = 0.8 * math.min(width, height)
local initial_offset = {x=0.4, y=0.25}
local offset = product_index - 1
-- TODO fixed precision format
rendering.draw_rectangle{
  color = {10,10,10,200},
  filled = true,
  left_top = add_positions{box.left_top, initial_offset, {x=-0.35, y=-0.35}, {x=0, y=(offset * 0.5)}},
  right_bottom = add_positions{box.left_top, initial_offset, {x=0.1, y=0.1}, {x=0, y=(offset * 0.5)}, {x=2, y=0.3}},
  surface = entity.surface,
  time_to_live = 120
}
rendering.bring_to_front(rendering.draw_sprite{
  sprite = product.type.."/"..product.name,
  target = add_positions{box.left_top, initial_offset, {x=0, y=(offset * 0.5)}},
  surface = entity.surface,
  time_to_live = 120,
  x_scale = 0.6,
  y_scale = 0.6
})
rendering.draw_text{
  text = round(product.rate_per_minute, 3).." / m",
  surface = entity.surface,
  target = add_positions{box.left_top, initial_offset, {x=0.4, y=-0.3}, {x=0, y=(offset * 0.5)}},
  color = {255,255,255},
  time_to_live = 120
}

]]