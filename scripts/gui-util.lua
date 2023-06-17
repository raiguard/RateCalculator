local flib_dictionary = require("__flib__/dictionary-lite")
local flib_format = require("__flib__/format")
local flib_gui = require("__flib__/gui-lite")
local flib_math = require("__flib__/math")
local flib_table = require("__flib__/table")

--- @alias DisplayCategory
--- | "products"
--- | "intermediates"
--- | "ingredients"

--- @alias DivisorSource
--- | "inserter_divisor"
--- | "materials_divisor",
--- | "transport_belt_divisor"

--- @alias GenericPrototype LuaEntityPrototype|LuaFluidPrototype|LuaItemPrototype

--- @class TimescaleData
--- @field divisor_required boolean?
--- @field divisor_source DivisorSource
--- @field multiplier double?
--- @field prefer_si boolean?
--- @field type_filter string?

local colors = {
  green = "150,255,150",
  red = "255,150,150",
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
    local precision = 0.001
    if math.abs(amount) >= 1000 then
      precision = 1
    elseif math.abs(amount) >= 100 then
      precision = 0.1
    elseif math.abs(amount) >= 10 then
      precision = 0.01
    end
    formatted = flib_format.number(flib_math.round(amount, precision))
  end
  if positive_prefix and amount > 0 then
    formatted = "+" .. formatted
  end
  return formatted
end

-- --- @param rates DisplayRatesSet
-- --- @param timescale_suffix LocalisedString
-- --- @param show_detailed_net_rates boolean
-- --- @return LocalisedString, LocalisedString, LocalisedString, LocalisedString
-- local function build_row_displays(rates, timescale_suffix, show_detailed_net_rates)
--   -- Always show power and heat as watts
--   --- @type LocalisedString
--   local caption_suffix = { "" }
--   local prefer_si = false
--   if rates.name == "rcalc-power-dummy" or rates.name == "rcalc-heat-dummy" then
--     timescale_suffix = ""
--     caption_suffix = { "si-unit-symbol-watt" }
--     prefer_si = true
--   end

--   local category = rates.category
--   --- @type LocalisedString
--   local tooltip = { "" }
--   local name = rates.localised_name
--   if rates.temperature then
--     name = {
--       "",
--       rates.localised_name,
--       " (",
--       { "format-degrees-c-compact", format_number(rates.temperature, false, false) },
--       ")",
--     }
--   end
--   --- @type LocalisedString
--   local tooltip_title = { "gui.rcalc-rate-tooltip-title", name }
--   --- @type LocalisedString
--   local machines_caption = { "" }
--   local caption_machine_icons, tooltip_machine_icons = build_machine_icons(rates)
--   local formatted_rate = ""
--   local formatted_rate_breakdown = ""
--   local rate_color = colors.white
--   if category == "products" then
--     formatted_rate = format_number(rates.output, prefer_si, false)
--     local formatted_machines = format_number(rates.output_machines, false, false)
--     machines_caption = { "gui.rcalc-machines-caption", caption_machine_icons, formatted_machines }
--     tooltip = {
--       "gui.rcalc-rate-tooltip",
--       tooltip_title,
--       tooltip_machine_icons,
--       { "", formatted_rate, caption_suffix, timescale_suffix },
--       { "", format_number(rates.output / rates.output_machines, false, false), caption_suffix, timescale_suffix },
--       formatted_machines,
--     }
--   elseif category == "ingredients" then
--     formatted_rate = format_number(rates.input, prefer_si, false)
--     local formatted_machines = format_number(rates.input_machines, false, false)
--     machines_caption = { "gui.rcalc-machines-caption", caption_machine_icons, formatted_machines }
--     tooltip = {
--       "gui.rcalc-rate-tooltip",
--       tooltip_title,
--       tooltip_machine_icons,
--       { "", formatted_rate, caption_suffix, timescale_suffix },
--       { "", format_number(rates.input / rates.input_machines, false, false), caption_suffix, timescale_suffix },
--       formatted_machines,
--     }
--   else
--     local net_rate = flib_math.round(rates.output - rates.input, 0.00001)
--     formatted_rate = format_number(net_rate, prefer_si, true)
--     if show_detailed_net_rates then
--       formatted_rate_breakdown = "[color=150,255,150]"
--         .. format_number(rates.output, prefer_si, false)
--         .. "[/color]-[color=255,150,150]"
--         .. format_number(rates.input, prefer_si, false)
--         .. "[/color]"
--     end
--     local net_machines = net_rate / (rates.output / rates.output_machines)
--     local formatted_net_machines = format_number(net_machines, false, true)
--     local formatted_output_machines = format_number(rates.output_machines, false, false)
--     if net_rate > 0 then
--       rate_color = colors.green
--     elseif net_rate < 0 then
--       rate_color = colors.red
--     end
--     machines_caption = {
--       "gui.rcalc-net-machines-caption",
--       { "gui.rcalc-machines-caption", caption_machine_icons, formatted_output_machines },
--       rate_color,
--       formatted_net_machines,
--     }
--     tooltip = {
--       "gui.rcalc-intermediate-tooltip",
--       tooltip_title,
--       tooltip_machine_icons,
--       rate_color,
--       { "", formatted_rate, caption_suffix, timescale_suffix },
--       formatted_net_machines,
--       { "", format_number(rates.output, prefer_si, false), caption_suffix, timescale_suffix },
--       { "", format_number(rates.output / rates.output_machines, false, false), caption_suffix, timescale_suffix },
--       formatted_output_machines,
--       { "", format_number(rates.input, prefer_si, false), caption_suffix, timescale_suffix },
--       { "", format_number(rates.input / rates.input_machines, false, false), caption_suffix, timescale_suffix },
--       format_number(rates.input_machines, false, false),
--     }
--   end

--   local rate_caption = { "gui.rcalc-rate-label", rate_color, formatted_rate, caption_suffix }
--   return machines_caption, rate_caption, tooltip, formatted_rate_breakdown
-- end

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

--- @param e EventData.on_gui_click
local function on_completion_checkbox_checked(e)
  local self = global.gui[e.player_index]
  if not self then
    return
  end
  local set = self.sets[self.selected_set_index]
  if set then
    set.completed[e.element.name] = e.element.state or nil
  end
end

--- @param e EventData.on_gui_click
local function on_row_icon_clicked(e)
  if not remote.interfaces["RecipeBook"] or not e.alt then
    return
  end
  local sprite = e.element.sprite
  local type, name = string.match(sprite, "(.*)/(.*)")
  if not type or not name then
    return
  end
  remote.call("RecipeBook", "open_page", e.player_index, type, name)
end
flib_gui.add_handlers({
  on_completion_checkbox_checked = on_completion_checkbox_checked,
  on_row_icon_clicked = on_row_icon_clicked,
})

-- --- @param parent LuaGuiElement
-- --- @param category DisplayCategory
-- --- @param rates DisplayRatesSet[]
-- --- @param show_machines boolean
-- --- @param show_intermediate_breakdowns boolean
-- --- @param timescale_suffix LocalisedString
-- --- @param completed Set<string>?
-- function gui_util.build_rates_table(
--   parent,
--   category,
--   rates,
--   show_machines,
--   show_intermediate_breakdowns,
--   timescale_suffix,
--   completed
-- )
--   --- @type GuiElemDef[]
--   local children = {}
--   for _, rates in pairs(rates) do
--     local path = rates.type .. "/" .. rates.name .. (rates.temperature or "")
--     if completed then
--       children[#children + 1] = {
--         type = "checkbox",
--         name = path,
--         style = "rcalc_completion_checkbox",
--         state = completed[path] or false,
--         handler = {
--           [defines.events.on_gui_checked_state_changed] = on_completion_checkbox_checked,
--         },
--       }
--     end
--     if rates.filtered then
--       children[#children + 1] = {
--         type = "sprite-button",
--         style = "rcalc_transparent_slot_filtered",
--         sprite = rates.type .. "/" .. rates.name,
--         number = rates.temperature,
--       }
--       if show_machines then
--         children[#children + 1] = { type = "label", style = "rcalc_rate_label", caption = "-" }
--       end
--       if show_intermediate_breakdowns then
--         children[#children + 1] = { type = "empty-widget" }
--       end
--       children[#children + 1] = { type = "label", style = "rcalc_rate_label", caption = "-" }

--       goto continue
--     end

--     local machines_caption, rate_caption, tooltip, rate_breakdown_caption =
--       build_row_displays(rates, timescale_suffix, show_intermediate_breakdowns)

--     children[#children + 1] = {
--       type = "sprite-button",
--       style = "rcalc_transparent_slot",
--       sprite = rates.type .. "/" .. rates.name,
--       number = rates.temperature,
--       tooltip = {
--         "",
--         tooltip,
--         remote.interfaces["RecipeBook"] and { "", "\n", { "gui.rcalc-open-in-recipe-book-instruction" } } or nil,
--       },
--       handler = { [defines.events.on_gui_click] = on_row_icon_clicked },
--     }
--     if show_machines then
--       children[#children + 1] = {
--         type = "label",
--         style = "rcalc_rate_label",
--         caption = machines_caption,
--         tooltip = tooltip,
--       }
--     end
--     children[#children + 1] =
--       { type = "empty-widget", style_mods = { height = 32, horizontally_stretchable = true }, tooltip = tooltip }
--     if #rate_breakdown_caption > 0 then
--       children[#children + 1] = {
--         type = "label",
--         style = "rcalc_rate_breakdown_label",
--         caption = rate_breakdown_caption,
--         tooltip = tooltip,
--       }
--     end
--     children[#children + 1] = {
--       type = "label",
--       style = "rcalc_rate_label",
--       caption = rate_caption,
--       tooltip = tooltip,
--     }

--     ::continue::
--   end
--   local flow = parent.add({ type = "flow", direction = "vertical" })
--   flow.add({ type = "label", style = "caption_label", caption = { "gui.rcalc-" .. category } })

--   --- @type uint
--   local column_count = 3
--   if completed then
--     column_count = column_count + 1
--   end
--   if show_machines then
--     column_count = column_count + 1
--   end
--   if show_intermediate_breakdowns then
--     column_count = column_count + 1
--   end
--   local table = flow.add({
--     type = "table",
--     style = category == "ingredients" and "rcalc_ingredients_table" or "rcalc_rates_table",
--     column_count = column_count,
--   })
--   table.style.column_alignments[column_count] = "right"
--   if show_intermediate_breakdowns then
--     table.style.column_alignments[column_count - 1] = "right"
--   end
--   flib_gui.add(table, children)
-- end

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

-- --- @param self GuiData
-- --- @return DisplayRatesSet[], DisplayRatesSet[], DisplayRatesSet[]
-- function gui_util.get_display_set(self)
--   --- @type table<DisplayCategory, DisplayRatesSet[]>
--   local out = {}
--   local timescale_data = gui_util.timescale_data[self.selected_timescale]
--   local manual_multiplier = self.manual_multiplier
--   local multiplier = timescale_data.multiplier or 1
--   local divisor, type_filter = gui_util.get_divisor(self)
--   local dictionary = flib_dictionary.get(self.player.index, "search") or {}
--   local show_power_input = self.player.mod_settings["rcalc-show-power-consumption"].value --[[@as boolean]]
--   local search_query = self.search_query
--   local set = self.sets[self.selected_set_index]
--   for _, rates in pairs(set.rates) do
--     local path = rates.type .. "/" .. rates.name
--     local search_name = dictionary[path] or string.gsub(rates.name, "%-", " ")
--     if not string.find(string.lower(search_name), search_query, nil, true) then
--       goto continue
--     end

--     local output, input = rates.output, rates.input
--     local output_machines, input_machines = rates.output_machines, rates.input_machines
--     local type, name = rates.type, rates.name

--     -- Ignore power input by default
--     if not show_power_input and name == "rcalc-power-dummy" then
--       input = 0
--       input_machines = 0
--     end

--     if input == 0 and output == 0 then
--       goto continue
--     end

--     local category = "products"
--     if input > 0 and output > 0 then
--       category = "intermediates"
--     elseif input > 0 then
--       category = "ingredients"
--     elseif output > 0 then
--       category = "products"
--     end

--     --- @type GenericPrototype
--     local prototype = game[type .. "_prototypes"][name]

--     local input, output = input, output
--     if divisor and type == "item" and timescale_data.divisor_source == "materials_divisor" then
--       output = output / prototype.stack_size
--       input = input / prototype.stack_size
--     end
--     local divisor = divisor or 1

--     local input_machine_counts = {}
--     -- Don't show machines if power consumption is disabled
--     if input > 0 then
--       for name, count in pairs(rates.input_machine_counts) do
--         input_machine_counts[name] = count * manual_multiplier
--       end
--     end
--     local output_machine_counts = {}
--     for name, count in pairs(rates.output_machine_counts) do
--       output_machine_counts[name] = count * manual_multiplier
--     end

--     -- Always show power and heat as watts, and never filter
--     local multiplier = multiplier
--     local type_filter = type_filter
--     if name == "rcalc-power-dummy" or name == "rcalc-heat-dummy" then
--       multiplier = 1
--       divisor = 1
--       type_filter = nil
--     end

--     --- @type DisplayRatesSet
--     local disp = {
--       category = category,
--       filtered = type_filter and type ~= type_filter or false,
--       input = input / divisor * multiplier * manual_multiplier,
--       input_machine_counts = input_machine_counts,
--       input_machines = input_machines * manual_multiplier,
--       localised_name = prototype.localised_name,
--       name = name,
--       output_machine_counts = output_machine_counts,
--       output_machines = output_machines * manual_multiplier,
--       output = output / divisor * multiplier * manual_multiplier,
--       type = type,
--       temperature = rates.temperature,
--     }
--     local list = out[category]
--     if not list then
--       list = {}
--       out[category] = list
--     end
--     list[#list + 1] = disp

--     ::continue::
--   end

--   for _, tbl in pairs(out) do
--     table.sort(tbl, function(a, b)
--       if a.filtered ~= b.filtered then
--         return b.filtered
--       end
--       local a_rate = a.output - a.input
--       local b_rate = b.output - b.input
--       if a_rate == b_rate then
--         local a_name, b_name = a.name, b.name
--         if a_name == b_name then
--           return (a.temperature or 0) > (b.temperature or 0)
--         end
--         return a.name > b.name
--       end
--       if a.category == "ingredients" then
--         return a_rate < b_rate
--       end
--       return a_rate > b_rate
--     end)
--   end

--   return out.ingredients, out.products, out.intermediates
-- end

--- @param self GuiData
--- @return double|uint?, string?
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
        divisor = cycles_per_second
          * (1 + prototype.inserter_stack_size_bonus + self.player.force.stack_inserter_capacity_bonus)
      else
        divisor = cycles_per_second
          * (1 + prototype.inserter_stack_size_bonus + self.player.force.inserter_stack_size_bonus)
      end
      type_filter = "item"
    end
  end

  return divisor, type_filter
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

--- @param counts MachineCounts
--- @param include_numbers boolean
--- @return string
local function build_machine_icons(counts, include_numbers)
  local output = ""
  for name, count in pairs(counts) do
    output = output .. "[entity=" .. name .. "] "
    if include_numbers then
      output = output .. count .. "  "
    end
  end
  return output
end

--- @param num number
--- @return string
local function get_net_color(num)
  if num > 0 then
    return colors.green
  elseif num < 0 then
    return colors.red
  else
    return colors.white
  end
end

--- @param self GuiData
--- @param set CalculationSet
function gui_util.update_rates(self, set)
  --- @type table<DisplayCategory, GuiElemDef[]>
  local category_elems = {
    products = {},
    intermediates = {},
    ingredients = {},
  }

  local timescale_data = gui_util.timescale_data[self.selected_timescale]
  local manual_multiplier = self.manual_multiplier
  local multiplier = timescale_data.multiplier or 1
  local divisor, type_filter = gui_util.get_divisor(self)
  local dictionary = flib_dictionary.get(self.player.index, "search") or {}
  local show_power_input = self.player.mod_settings["rcalc-show-power-consumption"].value --[[@as boolean]]
  local search_query = self.search_query

  --- @param rate Rate
  --- @return Rate
  local function scale_rate(rate)
    return {
      machine_counts = flib_table.map(rate.machine_counts, function(count)
        return count * manual_multiplier
      end),
      machines = rate.machines * manual_multiplier,
      rate = rate.rate / (divisor or 1) * multiplier * manual_multiplier,
    }
  end

  for path, rates in pairs(set.rates) do
    local output = scale_rate(rates.output)
    local input = scale_rate(rates.input)
    --- @type DisplayCategory
    local category = "products"
    if output.rate > 0 and input.rate > 0 then
      category = "intermediates"
    elseif input.rate > 0 then
      category = "ingredients"
    end

    if type_filter and type_filter ~= rates.type then
      goto continue
    end
    if category == "ingredients" and path == "item/rcalc-power-dummy" and not show_power_input then
      goto continue
    end
    local to_search = string.lower(dictionary[path] or rates.name)
    if not string.find(to_search, search_query, nil, true) then
      goto continue
    end

    local category_rate = category == "ingredients" and input or output

    local machines = format_number(category_rate.machines, false, false)
    local machines_caption = {
      "gui.rcalc-machines-caption",
      build_machine_icons(category_rate.machine_counts, false),
      machines,
    }

    local is_watts = path == "item/rcalc-power-dummy" or path == "item/rcalc-heat-dummy"

    local formatted_rate = ""
    local rate_color = colors.white
    if category == "intermediates" then
      local net_rate = flib_math.round(output.rate - input.rate, 0.00001) -- Floating point sucks
      local net_machines = net_rate / (output.rate / output.machines)
      local formatted_net_machines = format_number(net_machines, false, true)
      machines_caption =
        { "gui.rcalc-net-machines-caption", machines_caption, get_net_color(net_machines), formatted_net_machines }
      formatted_rate = format_number(net_rate, is_watts, true)
      rate_color = get_net_color(net_rate)
    else
      formatted_rate = format_number(category_rate.rate, is_watts, false)
    end

    local category_elems = category_elems[category]
    category_elems[#category_elems + 1] = {
      type = "flow",
      name = path,
      style = "rcalc_rates_flow",
      { type = "sprite-button", style = "rcalc_transparent_slot", sprite = path, ignored_by_interaction = true },
      { type = "label", style = "rcalc_machines_label", caption = machines_caption, ignored_by_interaction = true },
      { type = "empty-widget", style = "flib_horizontal_pusher", ignored_by_interaction = true },
      {
        type = "label",
        style = "rcalc_rate_label",
        caption = {
          "gui.rcalc-rate-label",
          formatted_rate,
          rate_color,
          is_watts and { "si-unit-symbol-watt" } or "",
        },
        ignored_by_interaction = true,
      },
    }

    ::continue::
  end

  local scroll = self.elems.rates_scroll_pane
  scroll.clear()

  local has_rates = false
  for category, children in pairs(category_elems) do
    if #children > 0 then
      has_rates = true
      flib_gui.add(scroll, {
        {
          type = "label",
          style = "subheader_caption_label",
          caption = { "gui.rcalc-" .. category },
          ignored_by_interaction = true,
        },
        { type = "table", style = "rcalc_rates_table", column_count = 1, children = children },
      })
    end
  end

  if not has_rates then
    flib_gui.add(scroll, {
      type = "flow",
      name = "no_rates_flow",
      style_mods = {
        horizontally_stretchable = true,
        height = 50,
        vertical_align = "center",
        horizontal_align = "center",
      },
      { type = "label", caption = { "gui.rcalc-no-rates-to-display" } },
    })
  end
end

return gui_util
