local flib_dictionary = require("__flib__/dictionary-lite")
local flib_format = require("__flib__/format")
local flib_gui = require("__flib__/gui-lite")
local flib_math = require("__flib__/math")

--- @alias DisplayCategory
--- | "products"
--- | "intermediates"
--- | "ingredients"

--- @class DisplayRatesSet: RatesSet
--- @field category DisplayCategory
--- @field filtered boolean
--- @field localised_name LocalisedString

--- @alias DivisorSource
--- | "inserter_divisor"
--- | "materials_divisor",
--- | "transport_belt_divisor"

--- @alias GenericPrototype LuaEntityPrototype|LuaFluidPrototype|LuaItemPrototype

--- @class MeasureData
--- @field divisor_required boolean?
--- @field divisor_source DivisorSource
--- @field multiplier double?
--- @field prefer_si boolean?
--- @field type_filter string?

--- @param rates DisplayRatesSet
--- @return string
local function build_machines_tooltip_icons(rates)
  local output = ""
  for name, count in pairs(rates.output_machine_counts) do
    output = output .. "[entity=" .. name .. "] ×" .. count .. "  "
  end
  if rates.output > 0 and rates.input > 0 then
    output = output .. "→  "
  end
  for name, count in pairs(rates.input_machine_counts) do
    output = output .. "[entity=" .. name .. "] ×" .. count .. "  "
  end
  return output
end

local colors = {
  green = "100,255,100",
  red = "255,100,100",
  white = "255,255,255",
}

--- @param amount number
--- @param prefer_si boolean
--- @param positive_prefix boolean
--- @return string
local function format_number(amount, prefer_si, positive_prefix)
  local formatted = ""
  if prefer_si or math.abs(amount) >= 10000 then
    formatted = flib_format.number(amount, true)
  else
    local precision = 0.01
    if math.abs(amount) >= 100 then
      precision = 1
    elseif math.abs(amount) >= 10 then
      precision = 0.1
    end
    formatted = flib_format.number(flib_math.round(amount, precision))
  end
  if positive_prefix and amount > 0 then
    formatted = "+" .. formatted
  end
  return formatted
end

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

--- @param parent LuaGuiElement
--- @param category DisplayCategory
--- @param rates DisplayRatesSet[]
--- @param show_machines boolean
--- @param suffix LocalisedString
--- @param prefer_si boolean
function gui_util.build_rates_table(parent, category, rates, show_machines, suffix, prefer_si)
  --- @type GuiElemDef[]
  local children = {}
  for _, rates in pairs(rates) do
    if rates.filtered then
      children[#children + 1] = {
        type = "sprite-button",
        style = "rcalc_transparent_slot_filtered",
        sprite = rates.type .. "/" .. rates.name,
        ignored_by_interaction = true,
      }
      if show_machines then
        children[#children + 1] = { type = "label", style = "rcalc_rates_table_label", caption = "-" }
      end
      children[#children + 1] = {
        type = "flow",
        { type = "empty-widget", style = "flib_horizontal_pusher" },
        { type = "label", style = "rcalc_rates_table_label", caption = "-" },
      }
      goto continue
    end

    -- Always show power and heat as watts
    local suffix = suffix
    local rate_caption_suffix = ""
    if rates.name == "rcalc-power-dummy" or rates.name == "rcalc-heat-dummy" then
      suffix = "W"
      rate_caption_suffix = "W"
    end

    local category = rates.category
    --- @type LocalisedString
    local tooltip = {}
    --- @type LocalisedString
    local tooltip_title = { "gui.rcalc-rate-tooltip-title", rates.localised_name }
    local machines_caption = ""
    local rate_caption = ""
    local machines_caption_icons = ""
    if category == "products" then
      rate_caption = format_number(rates.output, prefer_si, false)
      machines_caption = format_number(rates.output_machines, false, false)
      tooltip = {
        "gui.rcalc-rate-tooltip",
        tooltip_title,
        build_machines_tooltip_icons(rates),
        { "", rate_caption, suffix },
        { "", format_number(rates.output / rates.output_machines, false, false), suffix },
        machines_caption,
      }
      for name in pairs(rates.output_machine_counts) do
        machines_caption_icons = machines_caption_icons .. "[entity=" .. name .. "]"
      end
    elseif category == "ingredients" then
      rate_caption = format_number(rates.input, prefer_si, false)
      machines_caption = format_number(rates.input_machines, false, false)
      tooltip = {
        "gui.rcalc-rate-tooltip",
        tooltip_title,
        build_machines_tooltip_icons(rates),
        { "", rate_caption, suffix },
        { "", format_number(rates.input / rates.input_machines, false, false), suffix },
        machines_caption,
      }
      for name in pairs(rates.input_machine_counts) do
        machines_caption_icons = machines_caption_icons .. "[entity=" .. name .. "]"
      end
    else
      local net_rate = flib_math.round(rates.output - rates.input, 0.01)
      local rate_color = colors.white
      if net_rate > 0 then
        rate_color = colors.green
      elseif net_rate < 0 then
        rate_color = colors.red
      end
      local formatted_net_rate = format_number(net_rate, prefer_si, true)
      rate_caption = string.format("[color=%s]%s%s[/color]", rate_color, formatted_net_rate, rate_caption_suffix)
      rate_caption_suffix = ""
      local net_machines = net_rate / (rates.output / rates.output_machines)
      local net_machines_color = colors.white
      if net_machines > 0 then
        net_machines_color = colors.green
      elseif net_machines < 0 then
        net_machines_color = colors.red
      end
      local formatted_net_machines = format_number(net_machines, false, true)
      local formatted_output_machines = format_number(rates.output_machines, false, false)
      machines_caption = string.format(
        "%s  [color=%s](%s)[/color]",
        formatted_output_machines,
        net_machines_color,
        formatted_net_machines
      )
      for name in pairs(rates.output_machine_counts) do
        machines_caption_icons = machines_caption_icons .. "[entity=" .. name .. "]"
      end

      tooltip = {
        "gui.rcalc-intermediate-tooltip",
        tooltip_title,
        build_machines_tooltip_icons(rates),
        rate_color,
        { "", formatted_net_rate, suffix },
        formatted_net_machines,
        { "", format_number(rates.output, prefer_si, false), suffix },
        { "", format_number(rates.output / rates.output_machines, false, false), suffix },
        formatted_output_machines,
        { "", format_number(rates.input, prefer_si, false), suffix },
        { "", format_number(rates.input / rates.input_machines, false, false), suffix },
        format_number(rates.input_machines, false, false),
      }
    end
    children[#children + 1] = {
      type = "sprite-button",
      style = "rcalc_transparent_slot",
      sprite = rates.type .. "/" .. rates.name,
      tooltip = tooltip,
    }
    if show_machines then
      children[#children + 1] = {
        type = "label",
        style = "rcalc_rates_table_label",
        caption = machines_caption_icons .. " × " .. machines_caption,
        tooltip = tooltip,
      }
    end
    children[#children + 1] = {
      type = "flow",
      style_mods = { horizontal_spacing = 0 },
      tooltip = tooltip,
      { type = "empty-widget", style = "flib_horizontal_pusher", ignored_by_interaction = true },
      {
        type = "label",
        style = "rcalc_rates_table_label",
        caption = { "", rate_caption, rate_caption_suffix },
        ignored_by_interaction = true,
      },
    }

    ::continue::
  end
  flib_gui.add(parent, {
    type = "flow",
    direction = "vertical",
    {
      type = "label",
      style = "caption_label",
      caption = { "gui.rcalc-" .. category },
    },
    {
      type = "table",
      name = "table",
      style = show_machines and "rcalc_rates_table" or "rcalc_ingredients_table",
      column_count = show_machines and 3 or 2,
      children = children,
    },
  })
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
  local angle = math.acos((pickup_x * drop_x + pickup_y * drop_y) / (pickup_length * drop_length))
  -- Rotation speed is in full circles per tick
  local ticks_per_cycle = 2 * math.ceil(angle / (math.pi * 2) / inserter.inserter_rotation_speed)
  local extension_time = 2 * math.ceil(math.abs(pickup_length - drop_length) / inserter.inserter_extension_speed)
  if ticks_per_cycle < extension_time then
    ticks_per_cycle = extension_time
  end
  return 60 / ticks_per_cycle -- 60 = ticks per second
end

--- @param self GuiData
--- @param search_query string
--- @return DisplayRatesSet[], DisplayRatesSet[], DisplayRatesSet[]
function gui_util.get_display_set(self, search_query)
  --- @type table<DisplayCategory, DisplayRatesSet[]>
  local out = {}
  local measure_data = gui_util.measure_data[self.selected_measure]
  local manual_multiplier = self.manual_multiplier
  local multiplier = measure_data.multiplier or 1
  local divisor, type_filter = gui_util.get_divisor(self)
  local dictionary = flib_dictionary.get(self.player.index, "search") or {}
  local show_power_input = self.player.mod_settings["rcalc-show-power-consumption"].value
  for _, rates in pairs(self.calc_set.rates) do
    local path = rates.type .. "/" .. rates.name
    local search_name = dictionary[path] or string.gsub(rates.name, "%-", " ")
    if not string.find(string.lower(search_name), search_query, nil, true) then
      goto continue
    end

    -- Ignore power input by default
    if not show_power_input and rates.name == "rcalc-power-dummy" then
      rates.input = 0
      rates.input_machines = 0
      rates.input_machine_counts = {}
    end

    if rates.input == 0 and rates.output == 0 then
      goto continue
    end

    local category = "products"
    if rates.input > 0 and rates.output > 0 then
      category = "intermediates"
    elseif rates.input > 0 then
      category = "ingredients"
    elseif rates.output > 0 then
      category = "products"
    end

    --- @type GenericPrototype
    local prototype = game[rates.type .. "_prototypes"][rates.name]

    local input, output = rates.input, rates.output
    if divisor and rates.type == "item" and measure_data.divisor_source == "materials_divisor" then
      output = rates.output / prototype.stack_size
      input = rates.input / prototype.stack_size
    end
    local divisor = divisor or 1

    local input_machine_counts = {}
    for name, count in pairs(rates.input_machine_counts) do
      input_machine_counts[name] = count * manual_multiplier
    end
    local output_machine_counts = {}
    for name, count in pairs(rates.output_machine_counts) do
      output_machine_counts[name] = count * manual_multiplier
    end

    -- Always show power and heat as watts, and never filter
    local multiplier = multiplier
    local type_filter = type_filter
    if rates.name == "rcalc-power-dummy" or rates.name == "rcalc-heat-dummy" then
      multiplier = 1
      divisor = 1
      type_filter = nil
    end

    --- @type DisplayRatesSet
    local disp = {
      category = category,
      filtered = type_filter and rates.type ~= type_filter or false,
      input = input / divisor * multiplier * manual_multiplier,
      input_machine_counts = input_machine_counts,
      input_machines = rates.input_machines * manual_multiplier,
      localised_name = prototype.localised_name,
      name = rates.name,
      output_machine_counts = output_machine_counts,
      output_machines = rates.output_machines * manual_multiplier,
      output = output / divisor * multiplier * manual_multiplier,
      type = rates.type,
    }
    local list = out[category]
    if not list then
      list = {}
      out[category] = list
    end
    list[#list + 1] = disp

    ::continue::
  end

  for _, tbl in pairs(out) do
    table.sort(tbl, function(a, b)
      if a.filtered ~= b.filtered then
        return b.filtered
      end
      local a_rate = a.output - a.input
      local b_rate = b.output - b.input
      if a_rate == b_rate then
        return a.name > b.name
      end
      if a.category == "ingredients" then
        return a_rate < b_rate
      end
      return a_rate > b_rate
    end)
  end

  return out.ingredients, out.products, out.intermediates
end

--- @param self GuiData
--- @return double|uint?, string?
function gui_util.get_divisor(self)
  local measure_data = gui_util.measure_data[self.selected_measure]
  local type_filter

  --- @type double|uint?
  local divisor
  --- @type string?
  local divisor_source = measure_data.divisor_source
  if not divisor_source then
    return divisor, type_filter
  end

  --- @type string?
  local divisor_name = self[divisor_source]
  if not divisor_name then
    return divisor, type_filter
  end
  if measure_data.divisor_required and not divisor_name then
    local entities = game.get_filtered_entity_prototypes(global.elem_filters[measure_data.divisor_source])
    -- LuaCustomTable does not work with next()
    for name in pairs(entities) do
      divisor_name = name
      break
    end
  end

  if divisor_name then
    local prototype = game.entity_prototypes[divisor_name]
    if prototype.type == "container" or prototype.type == "logistic-container" then
      divisor = prototype.get_inventory_size(defines.inventory.chest)
      type_filter = "item"
    elseif prototype.type == "cargo-wagon" then
      divisor = prototype.get_inventory_size(defines.inventory.cargo_wagon)
      type_filter = "item"
    elseif prototype.type == "storage-tank" or prototype.type == "fluid-wagon" then
      divisor = prototype.fluid_capacity
      type_filter = "fluid"
    elseif prototype.type == "transport-belt" then
      divisor = prototype.belt_speed * 480
      type_filter = "item"
    elseif prototype.type == "inserter" then
      local cycles_per_second = gui_util.calc_inserter_cycles_per_second(prototype)
      if prototype.stack then
        divisor = cycles_per_second * self.player.force.stack_inserter_capacity_bonus
      else
        divisor = cycles_per_second * self.player.force.inserter_stack_size_bonus
      end
      type_filter = "item"
    end
  end

  return divisor, type_filter
end

--- @param filters EntityPrototypeFilter[]
function gui_util.get_first_prototype(filters)
  --- next() doesn't work on LuaCustomTable
  for name in pairs(game.get_filtered_entity_prototypes(filters)) do
    return name
  end
end

--- @type table<Measure, MeasureData>
gui_util.measure_data = {
  ["per-second"] = { divisor_source = "materials_divisor", multiplier = 1 },
  ["per-minute"] = { divisor_source = "materials_divisor", multiplier = 60 },
  ["per-hour"] = { divisor_source = "materials_divisor", multiplier = 60 * 60 },
  ["transport-belts"] = { divisor_required = true, divisor_source = "transport_belt_divisor", type_filter = "item" },
  ["inserters"] = { divisor_required = true, divisor_source = "inserter_divisor", type_filter = "item" },
}

--- @type Measure[]
gui_util.ordered_measures = {
  "per-second",
  "per-minute",
  "per-hour",
  "transport-belts",
  "inserters",
}

return gui_util
