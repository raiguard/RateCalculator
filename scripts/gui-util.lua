local flib_dictionary = require("__flib__/dictionary-lite")
local flib_math = require("__flib__/math")

--- @alias DivisorSource
--- | "inserter_divisor"
--- | "materials_divisor",
--- | "transport_belt_divisor"

--- @class TimescaleData
--- @field divisor_required boolean?
--- @field divisor_source DivisorSource
--- @field multiplier double?
--- @field prefer_si boolean?
--- @field type_filter string?
--- @field suffix LocalisedString?

--- @class GuiUtil
local gui_util = {}

function gui_util.build_divisor_filters()
  --- @type EntityPrototypeFilter[]
  local materials = {}
  for _, entity in
    pairs(game.get_filtered_entity_prototypes({
      { filter = "type", type = "container" },
      { filter = "type", type = "logistic-container" },
    }))
  do
    local stacks = entity.get_inventory_size(defines.inventory.chest)
    if stacks and stacks > 0 and entity.group.name ~= "other" and entity.group.name ~= "environment" then
      materials[#materials + 1] = { filter = "name", name = entity.name }
    end
  end
  for _, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "cargo-wagon" } })) do
    local stacks = entity.get_inventory_size(defines.inventory.cargo_wagon)
    if stacks > 0 and entity.group.name ~= "other" and entity.group.name ~= "environment" then
      materials[#materials + 1] = { filter = "name", name = entity.name }
    end
  end
  for _, entity in
    pairs(game.get_filtered_entity_prototypes({
      { filter = "type", type = "storage-tank" },
      { filter = "type", type = "fluid-wagon" },
    }))
  do
    local capacity = entity.fluid_capacity
    if capacity > 0 and entity.group.name ~= "other" and entity.group.name ~= "environment" then
      materials[#materials + 1] = { filter = "name", name = entity.name }
    end
  end

  --- @type table<DivisorSource, EntityPrototypeFilter[]>
  global.elem_filters = {
    inserter_divisor = { { filter = "type", type = "inserter" } },
    materials_divisor = materials,
    transport_belt_divisor = { { filter = "type", type = "transport-belt" } },
  }
end

function gui_util.build_dictionaries()
  flib_dictionary.new("search")
  for name, prototype in pairs(game.fluid_prototypes) do
    flib_dictionary.add("search", "fluid/" .. name, prototype.localised_name)
  end
  for name, prototype in pairs(game.item_prototypes) do
    flib_dictionary.add("search", "item/" .. name, prototype.localised_name)
  end
end

--- @param inserter LuaEntityPrototype
--- @return double
function gui_util.calc_inserter_cycles_per_second(inserter)
  local pickup_vector = inserter.inserter_pickup_position --[[@as Vector]]
  local drop_vector = inserter.inserter_drop_position --[[@as Vector]]
  local pickup_x, pickup_y, drop_x, drop_y = pickup_vector[1], pickup_vector[2], drop_vector[1], drop_vector[2]
  local pickup_length = math.sqrt(pickup_x * pickup_x + pickup_y * pickup_y)
  local drop_length = math.sqrt(drop_x * drop_x + drop_y * drop_y)
  -- Get angle from the dot product
  -- XXX: Imprecision can make this return slightly outside the allowed bounds for acos, so clamp it
  local norm_dot = flib_math.clamp((pickup_x * drop_x + pickup_y * drop_y) / (pickup_length * drop_length), -1, 1)
  local angle = math.acos(norm_dot)
  -- Rotation speed is in full circles per tick
  local ticks_per_cycle = 2 * math.ceil(angle / (math.pi * 2) / inserter.inserter_rotation_speed)
  local extension_time = 2 * math.ceil(math.abs(pickup_length - drop_length) / inserter.inserter_extension_speed)
  if ticks_per_cycle < extension_time then
    ticks_per_cycle = extension_time
  end
  return 60 / ticks_per_cycle -- 60 = ticks per second
end

--- @param self GuiData
--- @return double|uint?, string?, boolean?
function gui_util.get_divisor(self)
  local timescale_data = gui_util.timescale_data[self.selected_timescale]
  local type_filter

  --- @type double|uint?
  local divisor
  --- @type string?
  local divisor_source = timescale_data.divisor_source
  if not divisor_source then
    return
  end

  --- @type string?
  local divisor_name = self[divisor_source]
  if not divisor_name then
    return
  end
  if timescale_data.divisor_required and not divisor_name then
    local entities = game.get_filtered_entity_prototypes(global.elem_filters[timescale_data.divisor_source])
    -- LuaCustomTable does not work with next()
    for name in pairs(entities) do
      divisor_name = name
      break
    end
  end

  local divide_stacks = false
  if divisor_name then
    local prototype = game.entity_prototypes[divisor_name]
    if prototype.type == "container" or prototype.type == "logistic-container" then
      divisor = prototype.get_inventory_size(defines.inventory.chest)
      type_filter = "item"
      divide_stacks = true
    elseif prototype.type == "cargo-wagon" then
      divisor = prototype.get_inventory_size(defines.inventory.cargo_wagon)
      type_filter = "item"
      divide_stacks = true
    elseif prototype.type == "storage-tank" or prototype.type == "fluid-wagon" then
      divisor = prototype.fluid_capacity
      type_filter = "fluid"
    elseif prototype.type == "transport-belt" then
      divisor = prototype.belt_speed * 480
      type_filter = "item"
    elseif prototype.type == "inserter" then
      local cycles_per_second = gui_util.calc_inserter_cycles_per_second(prototype)
      if prototype.stack then
        divisor = cycles_per_second
          * (1 + prototype.inserter_stack_size_bonus + self.player.force.stack_inserter_capacity_bonus)
      else
        divisor = cycles_per_second
          * (1 + prototype.inserter_stack_size_bonus + self.player.force.inserter_stack_size_bonus)
      end
      type_filter = "item"
    end
  end

  return divisor, type_filter, divide_stacks
end

--- @param filters EntityPrototypeFilter[]
function gui_util.get_first_prototype(filters)
  -- XXX: next() doesn't work on LuaCustomTable
  for name in pairs(game.get_filtered_entity_prototypes(filters)) do
    return name
  end
end

--- @type table<Timescale, TimescaleData>
gui_util.timescale_data = {
  ["per-second"] = { divisor_source = "materials_divisor", multiplier = 1 },
  ["per-minute"] = { divisor_source = "materials_divisor", multiplier = 60 },
  ["per-hour"] = { divisor_source = "materials_divisor", multiplier = 60 * 60 },
  ["transport-belts"] = { divisor_required = true, divisor_source = "transport_belt_divisor", type_filter = "item" },
  ["inserters"] = { divisor_required = true, divisor_source = "inserter_divisor", type_filter = "item" },
}

--- @type Timescale[]
gui_util.ordered_timescales = {
  "per-second",
  "per-minute",
  "per-hour",
  "transport-belts",
  "inserters",
}

return gui_util
