local flib_dictionary = require("__flib__/dictionary-lite")
local flib_format = require("__flib__/format")
local flib_gui = require("__flib__/gui-lite")
local flib_math = require("__flib__/math")
local flib_table = require("__flib__/table")

--- @param filters EntityPrototypeFilter[]
local function get_first_prototype(filters)
  --- next() doesn't work on LuaCustomTable
  for name in pairs(game.get_filtered_entity_prototypes(filters)) do
    return name
  end
end

local function build_divisor_filters()
  --- @type EntityPrototypeFilter[]
  local materials = {}
  for _, entity in
    pairs(game.get_filtered_entity_prototypes({
      { filter = "type", type = "container" },
      { filter = "type", type = "logistic-container" },
    }))
  do
    local stacks = entity.get_inventory_size(defines.inventory.chest)
    if stacks > 0 and entity.group.name ~= "other" and entity.group.name ~= "environment" then
      table.insert(materials, { filter = "name", name = entity.name })
    end
  end
  for _, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "type", type = "cargo-wagon" } })) do
    local stacks = entity.get_inventory_size(defines.inventory.cargo_wagon)
    if stacks > 0 and entity.group.name ~= "other" and entity.group.name ~= "environment" then
      table.insert(materials, { filter = "name", name = entity.name })
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
      table.insert(materials, { filter = "name", name = entity.name })
    end
  end

  --- @type table<DivisorSource, EntityPrototypeFilter[]>
  global.elem_filters = {
    inserter_divisor = { { filter = "type", type = "inserter" } },
    materials_divisor = materials,
    transport_belt_divisor = { { filter = "type", type = "transport-belt" } },
  }
end

local function build_dictionaries()
  -- FIXME: Fix this on flib's side
  if not global.__flib.dictionary.raw.search then
    flib_dictionary.new("search")
  end
  for name, prototype in pairs(game.entity_prototypes) do
    flib_dictionary.add("search", "entity/" .. name, prototype.localised_name)
  end
  for name, prototype in pairs(game.fluid_prototypes) do
    flib_dictionary.add("search", "fluid/" .. name, prototype.localised_name)
  end
  for name, prototype in pairs(game.item_prototypes) do
    flib_dictionary.add("search", "item/" .. name, prototype.localised_name)
  end
end

local full_circle_in_radians = math.pi * 2

--- @param inserter LuaEntityPrototype
--- @return double
local function calc_inserter_cycles_per_second(inserter)
  local pickup_vector = inserter.inserter_pickup_position --[[@as Vector]]
  local drop_vector = inserter.inserter_drop_position --[[@as Vector]]
  local pickup_x, pickup_y, drop_x, drop_y = pickup_vector[1], pickup_vector[2], drop_vector[1], drop_vector[2]
  local pickup_length = math.sqrt(pickup_x * pickup_x + pickup_y * pickup_y)
  local drop_length = math.sqrt(drop_x * drop_x + drop_y * drop_y)
  -- Get angle from the dot product
  local angle = math.acos((pickup_x * drop_x + pickup_y * drop_y) / (pickup_length * drop_length))
  -- Rotation speed is in full circles per tick
  local ticks_per_cycle = 2 * math.ceil(angle / full_circle_in_radians / inserter.inserter_rotation_speed)
  local extension_time = 2 * math.ceil(math.abs(pickup_length - drop_length) / inserter.inserter_extension_speed)
  if ticks_per_cycle < extension_time then
    ticks_per_cycle = extension_time
  end
  return 60 / ticks_per_cycle -- 60 = ticks per second
end

--- @class GuiData
--- @field elems table<string, LuaGuiElement>
--- @field inserter_divisor string
--- @field manual_multiplier double
--- @field materials_divisor string?
--- @field pinned boolean
--- @field player LuaPlayer
--- @field search_open boolean
--- @field search_query string
--- @field selected_measure Measure
--- @field calc_set CalculationSet
--- @field transport_belt_divisor string

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
  if prefer_si or amount >= 10000 or amount <= -10000 then
    formatted = flib_format.number(amount, true)
  else
    local precision = 0.01
    if amount >= 100 or amount <= -100 then
      precision = 1
    elseif amount >= 10 or amount <= -10 then
      precision = 0.1
    end
    formatted = flib_format.number(flib_math.round(amount, precision))
  end
  if positive_prefix and amount > 0 then
    formatted = "+" .. formatted
  end
  return formatted
end

--- @type Measure[]
local ordered_measures = {
  "per-second",
  "per-minute",
  "per-hour",
  "transport-belts",
  "inserters",
  "power",
  "heat",
}

--- @class MeasureData
--- @field divisor_source DivisorSource
--- @field multiplier double?
--- @field source MeasureSource?
--- @field type_filter string?
--- @field prefer_si boolean?

--- @alias DivisorSource
--- | "inserter_divisor"
--- | "materials_divisor",
--- | "transport_belt_divisor"

--- @alias MeasureSource
--- | "materials"
--- | "power"
--- | "heat"

--- @type table<Measure, MeasureData>
local measure_data = {
  ["per-second"] = { divisor_source = "materials_divisor", multiplier = 1 },
  ["per-minute"] = { divisor_source = "materials_divisor", multiplier = 60 },
  ["per-hour"] = { divisor_source = "materials_divisor", multiplier = 60 * 60 },
  ["transport-belts"] = { divisor_required = true, divisor_source = "transport_belt_divisor", type_filter = "item" },
  ["inserters"] = { divisor_required = true, divisor_source = "inserter_divisor", type_filter = "item" },
  ["power"] = { source = "power", prefer_si = true },
  ["heat"] = { source = "heat", prefer_si = true },
}

--- @param self GuiData
--- @return double|uint?, string?
local function get_divisor(self)
  local measure_data = measure_data[self.selected_measure]
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
      local cycles_per_second = calc_inserter_cycles_per_second(prototype)
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

--- @alias DisplayCategory
--- | "products"
--- | "intermediates"
--- | "ingredients"

--- @alias GenericPrototype LuaEntityPrototype|LuaFluidPrototype|LuaItemPrototype

--- @class DisplayRatesSet: RatesSet
--- @field category DisplayCategory
--- @field filtered boolean
--- @field localised_name LocalisedString

--- @param self GuiData
--- @param search_query string
--- @return DisplayRatesSet[], DisplayRatesSet[], DisplayRatesSet[]
local function get_display_set(self, search_query)
  --- @type table<DisplayCategory, DisplayRatesSet[]>
  local out = {}
  local measure_data = measure_data[self.selected_measure]
  local manual_multiplier = self.manual_multiplier
  local multiplier = measure_data.multiplier or 1
  local divisor, type_filter = get_divisor(self)
  local dictionary = flib_dictionary.get(self.player.index, "search") or {}
  for _, rates in pairs(self.calc_set.rates[measure_data.source or "materials"] or {}) do
    local path = rates.type .. "/" .. rates.name
    local search_name = dictionary[path] or string.gsub(rates.name, "%-", " ")
    if not string.find(string.lower(search_name), search_query, nil, true) then
      goto continue
    end

    local category = "products"
    if rates.input > 0 and rates.output > 0 then
      category = "intermediates"
    elseif rates.input > 0 then
      category = "ingredients"
    elseif rates.output > 0 then
      category = "products"
    else
      goto continue
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
    table.insert(list, disp)

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
      return a_rate > b_rate
    end)
  end

  return out.ingredients, out.products, out.intermediates
end

--- @param parent LuaGuiElement
--- @param category DisplayCategory
--- @param rates DisplayRatesSet[]
--- @param suffix LocalisedString
--- @param prefer_si boolean
local function build_rates_table(parent, category, rates, suffix, prefer_si)
  --- @type GuiElemDef[]
  local children = {}
  for _, rates in pairs(rates) do
    if rates.filtered then
      table.insert(children, {
        type = "sprite-button",
        style = "rcalc_transparent_slot_filtered",
        sprite = rates.type .. "/" .. rates.name,
        ignored_by_interaction = true,
      })
      if category ~= "ingredients" then
        table.insert(children, { type = "label", style = "rcalc_rates_table_label", caption = "-" })
      end
      table.insert(children, {
        type = "flow",
        { type = "empty-widget", style = "flib_horizontal_pusher" },
        { type = "label", style = "rcalc_rates_table_label", caption = "-" },
      })
      goto continue
    end

    local category = rates.category
    --- @type LocalisedString
    local tooltip = {}
    --- @type LocalisedString
    local tooltip_title = { "gui.rcalc-rate-tooltip-title", rates.localised_name }
    local machines_caption = ""
    local rate_caption = ""
    local machine_icons = ""
    if category == "products" then
      rate_caption = format_number(rates.output, prefer_si, false)
      machines_caption = format_number(rates.output_machines, false, false)
      tooltip = {
        "gui.rcalc-rate-tooltip",
        tooltip_title,
        { "", rate_caption, suffix },
        { "", format_number(rates.output / rates.output_machines, false, false), suffix },
        machines_caption,
      }
      for name in pairs(rates.output_machine_counts) do
        machine_icons = machine_icons .. "[entity=" .. name .. "]"
      end
    elseif category == "ingredients" then
      rate_caption = format_number(rates.input, prefer_si, false)
      machines_caption = format_number(rates.input_machines, false, false)
      tooltip = {
        "gui.rcalc-rate-tooltip",
        tooltip_title,
        { "", rate_caption, suffix },
        { "", format_number(rates.input / rates.input_machines, false, false), suffix },
        machines_caption,
      }
      for name in pairs(rates.input_machine_counts) do
        machine_icons = machine_icons .. "[entity=" .. name .. "]"
      end
    else
      local net_rate = rates.output - rates.input
      local rate_color = colors.white
      if net_rate > 0 then
        rate_color = colors.green
      elseif net_rate < 0 then
        rate_color = colors.red
      end
      local formatted_net_rate = format_number(net_rate, prefer_si, true)
      rate_caption = string.format("[color=%s]%s[/color]", rate_color, formatted_net_rate)
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
        machine_icons = machine_icons .. "[entity=" .. name .. "]"
      end

      tooltip = {
        "gui.rcalc-intermediate-tooltip",
        tooltip_title,
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
    table.insert(children, {
      type = "sprite-button",
      style = "rcalc_transparent_slot",
      sprite = rates.type .. "/" .. rates.name,
      tooltip = tooltip,
    })
    if category ~= "ingredients" then
      table.insert(children, {
        type = "label",
        style = "rcalc_rates_table_label",
        caption = machine_icons .. " × " .. machines_caption,
        tooltip = tooltip,
      })
    end
    table.insert(children, {
      type = "flow",
      style_mods = { horizontal_spacing = 0 },
      tooltip = tooltip,
      { type = "empty-widget", style = "flib_horizontal_pusher", ignored_by_interaction = true },
      {
        type = "label",
        style = "rcalc_rates_table_label",
        caption = rate_caption,
        ignored_by_interaction = true,
      },
    })

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
      style = category == "ingredients" and "rcalc_ingredients_table" or "rcalc_rates_table",
      column_count = category == "ingredients" and 2 or 3,
      children = children,
    },
  })
end

--- @class Gui
local gui = {}

--- @param self GuiData
local function toggle_search(self)
  local search_open = not self.search_open
  self.search_open = search_open
  local button = self.elems.search_button
  button.sprite = search_open and "utility/search_black" or "utility/search_white"
  button.style = search_open and "flib_selected_frame_action_button" or "frame_action_button"
  local textfield = self.elems.search_textfield
  textfield.visible = search_open
  self.search_open = search_open
  if search_open then
    textfield.focus()
    textfield.select_all()
  else
    textfield.text = ""
    self.search_query = ""
    gui.update(self)
  end
end

local handlers = {}
handlers = {
  --- @param self GuiData
  on_window_closed = function(self)
    if self.pinned then
      return
    end
    if self.search_open then
      toggle_search(self)
      self.player.opened = self.elems.rcalc_window
      return
    end
    self.elems.rcalc_window.visible = false
  end,

  --- @param self GuiData
  --- @param e EventData.on_gui_click
  on_titlebar_click = function(self, e)
    if e.button ~= defines.mouse_button_type.middle then
      return
    end
    self.elems.rcalc_window.force_auto_center()
  end,

  --- @param self GuiData
  on_close_button_click = function(self)
    self.elems.rcalc_window.visible = false
    self.player.opened = nil
  end,

  --- @param self GuiData
  --- @param e EventData.on_gui_click
  on_pin_button_click = function(self, e)
    local pinned = not self.pinned
    e.element.sprite = pinned and "flib_pin_black" or "flib_pin_white"
    e.element.style = pinned and "flib_selected_frame_action_button" or "frame_action_button"
    self.pinned = pinned
    if pinned then
      self.player.opened = nil
      self.elems.close_button.tooltip = { "gui.close" }
      self.elems.search_button.tooltip = { "gui.search" }
    else
      self.player.opened = self.elems.rcalc_window
      self.elems.close_button.tooltip = { "gui.close-instruction" }
      self.elems.search_button.tooltip = { "gui.flib-search-instruction" }
    end
  end,

  --- @param self GuiData
  on_search_button_click = function(self)
    toggle_search(self)
  end,

  --- @param self GuiData
  --- @param e EventData.on_gui_text_changed
  on_search_text_changed = function(self, e)
    self.search_query = string.lower(e.text)
    gui.update(self)
  end,

  --- @param self GuiData
  --- @param e EventData.on_gui_elem_changed
  on_divisor_elem_changed = function(self, e)
    local entity_name = e.element.elem_value --[[@as string?]]
    local measure = self.selected_measure
    local measure_data = measure_data[measure]
    if measure_data.divisor_required and not entity_name then
      e.element.elem_value = self[measure_data.divisor_source]
      return
    end
    self[measure_data.divisor_source] = entity_name
    gui.update(self)
  end,

  --- @param self GuiData
  --- @param e EventData.on_gui_selection_state_changed
  on_measure_dropdown_changed = function(self, e)
    local new_measure = ordered_measures[e.element.selected_index]
    self.selected_measure = new_measure
    gui.update(self)
  end,

  --- @param self GuiData
  --- @param e EventData.on_gui_text_changed
  on_multiplier_textfield_changed = function(self, e)
    local new_value = tonumber(e.element.text)
    if not new_value or new_value == 0 then
      return
    end
    self.manual_multiplier = new_value
    gui.update(self)
  end,

  --- @param self GuiData
  --- @param e EventData.on_gui_click
  on_multiplier_nudge_clicked = function(self, e)
    self.manual_multiplier = math.max(1, math.floor(self.manual_multiplier) + e.element.tags.delta)
    gui.update(self)
  end,
}

flib_gui.add_handlers(handlers, function(e, handler)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local self = gui.get(player)
  if not self then
    return
  end
  handler(self, e)
end)

--- @param name string
--- @param sprite SpritePath
--- @param tooltip LocalisedString
--- @param handler GuiElemHandler
--- @return GuiElemDef
local function frame_action_button(name, sprite, tooltip, handler)
  return {
    type = "sprite-button",
    name = name,
    style = "frame_action_button",
    sprite = sprite .. "_white",
    hovered_sprite = sprite .. "_black",
    clicked_sprite = sprite .. "_black",
    tooltip = tooltip,
    mouse_button_filter = { "left" },
    handler = { [defines.events.on_gui_click] = handler },
  }
end

--- @param player LuaPlayer
--- @return GuiData
function gui.build(player)
  gui.destroy(player)

  local elems = flib_gui.add(player.gui.screen, {
    type = "frame",
    name = "rcalc_window",
    direction = "vertical",
    elem_mods = { auto_center = true },
    visible = false,
    handler = { [defines.events.on_gui_closed] = handlers.on_window_closed },
    {
      type = "flow",
      style = "flib_titlebar_flow",
      drag_target = "rcalc_window",
      handler = { [defines.events.on_gui_click] = handlers.on_titlebar_click },
      {
        type = "label",
        style = "frame_title",
        caption = { "mod-name.RateCalculator" },
        ignored_by_interaction = true,
      },
      { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
      {
        type = "textfield",
        name = "search_textfield",
        style_mods = { top_margin = -2, bottom_margin = 1, width = 100 },
        visible = false,
        clear_and_focus_on_right_click = true,
        lose_focus_on_confirm = true,
        handler = { [defines.events.on_gui_text_changed] = handlers.on_search_text_changed },
      },
      frame_action_button(
        "search_button",
        "utility/search",
        { "gui.flib-search-instruction" },
        handlers.on_search_button_click
      ),
      frame_action_button("pin_button", "flib_pin", { "gui.flib-keep-open" }, handlers.on_pin_button_click),
      frame_action_button("close_button", "utility/close", { "gui.close-instruction" }, handlers.on_close_button_click),
    },
    {
      type = "frame",
      style = "inside_shallow_frame",
      style_mods = { minimal_width = 414 },
      direction = "vertical",
      {
        type = "frame",
        style = "subheader_frame",
        { type = "label", style = "subheader_caption_label", caption = { "gui.rcalc-measure" } },
        { type = "empty-widget", style = "flib_horizontal_pusher" },
        {
          type = "choose-elem-button",
          name = "measure_divisor_chooser",
          style = "rcalc_units_choose_elem_button",
          elem_type = "entity",
          tooltip = { "gui.rcalc-capacity-divisor-description" },
          handler = { [defines.events.on_gui_elem_changed] = handlers.on_divisor_elem_changed },
        },
        {
          type = "drop-down",
          name = "measure_dropdown",
          items = flib_table.map(ordered_measures, function(measure)
            return { "gui.rcalc-measure-" .. measure }
          end),
          handler = { [defines.events.on_gui_selection_state_changed] = handlers.on_measure_dropdown_changed },
        },
        { type = "label", caption = "[img=quantity-multiplier]" },
        {
          type = "flow",
          style_mods = { horizontal_spacing = 2 },
          {
            type = "textfield",
            name = "multiplier_textfield",
            style = "short_number_textfield",
            style_mods = { width = 40, horizontal_align = "center" },
            numeric = true,
            allow_decimal = true,
            clear_and_focus_on_right_click = true,
            lose_focus_on_confirm = true,
            tooltip = { "gui.rcalc-manual-multiplier-description" },
            text = "1",
            handler = { [defines.events.on_gui_text_changed] = handlers.on_multiplier_textfield_changed },
          },
          {
            type = "flow",
            style_mods = { vertical_spacing = 0, top_margin = 2 },
            direction = "vertical",
            {
              type = "sprite-button",
              style = "tool_button",
              style_mods = { width = 20, height = 14, padding = -1 },
              sprite = "rcalc_nudge_increase",
              tooltip = "+1",
              tags = { delta = 1 },
              handler = { [defines.events.on_gui_click] = handlers.on_multiplier_nudge_clicked },
            },
            {
              type = "sprite-button",
              style = "tool_button",
              style_mods = { width = 20, height = 14, padding = -1 },
              sprite = "rcalc_nudge_decrease",
              tooltip = "-1",
              tags = { delta = -1 },
              handler = { [defines.events.on_gui_click] = handlers.on_multiplier_nudge_clicked },
            },
          },
        },
      },
      {
        type = "scroll-pane",
        style = "rcalc_content_scroll_pane",
        {
          type = "flow",
          name = "main_content_flow",
          style_mods = { horizontal_spacing = 8 },
        },
      },
    },
  })

  player.opened = elems.rcalc_window

  --- @type GuiData
  local self = {
    elems = elems,
    inserter_divisor = get_first_prototype(global.elem_filters.inserter_divisor),
    manual_multiplier = 1,
    pinned = false,
    player = player,
    search_open = false,
    search_query = "",
    selected_measure = "per-minute",
    transport_belt_divisor = get_first_prototype(global.elem_filters.transport_belt_divisor),
  }
  global.gui[player.index] = self

  return self
end

--- @param player LuaPlayer
function gui.destroy(player)
  local self = global.gui[player.index]
  if not self then
    return
  end
  local window = self.elems.rcalc_window
  if not window.valid then
    return
  end
  window.destroy()
end

--- @param player LuaPlayer
function gui.get(player)
  local self = global.gui[player.index]
  if not self or not self.elems.rcalc_window.valid then
    self = gui.build(player)
  end
  return self
end

--- @param self GuiData
function gui.update(self)
  local elems = self.elems

  local measure = self.selected_measure
  local measure_data = measure_data[measure]

  local measure_divisor_chooser = elems.measure_divisor_chooser
  if measure_data.divisor_source then
    measure_divisor_chooser.visible = true
    measure_divisor_chooser.elem_filters = global.elem_filters[measure_data.divisor_source]
    measure_divisor_chooser.elem_value = self[measure_data.divisor_source]
  else
    measure_divisor_chooser.visible = false
  end
  elems.measure_dropdown.selected_index = flib_table.find(ordered_measures, measure) --[[@as uint]]
  elems.multiplier_textfield.text = tostring(self.manual_multiplier)

  local prefer_si = measure_data.prefer_si or false
  local suffix = { "gui.rcalc-measure-suffix-" .. measure }

  local ingredients, products, intermediates = get_display_set(self, self.search_query)
  local main_content_flow = self.elems.main_content_flow
  main_content_flow.clear()
  if ingredients then
    build_rates_table(main_content_flow, "ingredients", ingredients, suffix, prefer_si)
  end
  if ingredients and (products or intermediates) then
    flib_gui.add(
      main_content_flow,
      { type = "line", style_mods = { top_margin = -2, bottom_margin = -2 }, direction = "vertical" }
    )
  end
  if not products and not intermediates then
    return
  end
  local right_content_flow = main_content_flow.add({ type = "flow", direction = "vertical" })
  if products then
    build_rates_table(right_content_flow, "products", products, suffix, prefer_si)
    if intermediates then
      flib_gui.add(right_content_flow, {
        type = "line",
        style_mods = { left_margin = -4, right_margin = -4 },
        direction = "horizontal",
      })
    end
  end
  if intermediates then
    build_rates_table(right_content_flow, "intermediates", intermediates, suffix, prefer_si)
  end
end

--- @param player LuaPlayer
--- @param set CalculationSet?
function gui.show(player, set)
  local self = gui.get(player)
  if not self then
    return
  end
  if set then
    self.calc_set = set
  end
  if not self.calc_set then
    return
  end
  gui.update(self)
  self.elems.rcalc_window.visible = true
  if not self.pinned then
    player.opened = self.elems.rcalc_window
  end
end

function gui.on_init()
  --- @type table<uint, GuiData>
  global.gui = {}

  build_divisor_filters()
  build_dictionaries()
end

function gui.on_configuration_changed()
  build_divisor_filters()
  build_dictionaries()

  for _, player in pairs(game.players) do
    gui.destroy(player)
  end
end

gui.events = {
  --- @param e EventData.CustomInputEvent
  ["rcalc-linked-focus-search"] = function(e)
    local player = game.get_player(e.player_index)
    if not player then
      return
    end
    local self = gui.get(player)
    if not self or self.pinned or not self.elems.rcalc_window.visible then
      return
    end
    toggle_search(self)
  end,
}

return gui
