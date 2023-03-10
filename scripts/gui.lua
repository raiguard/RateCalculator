local flib_format = require("__flib__/format")
local flib_math = require("__flib__/math")
local flib_gui = require("__flib__/gui-lite")
local flib_table = require("__flib__/table")

--- @class Gui
--- @field current_set_index integer
--- @field elems table<string, LuaGuiElement>
--- @field player LuaPlayer
--- @field pinned boolean
--- @field search_open boolean

local suffix_list = {
  { "Y", 1e24 }, -- yotta
  { "Z", 1e21 }, -- zetta
  { "E", 1e18 }, -- exa
  { "P", 1e15 }, -- peta
  { "T", 1e12 }, -- tera
  { "G", 1e9 }, -- giga
  { "M", 1e6 }, -- mega
  { "k", 1e3 }, -- kilo
}

--- @param amount number
--- @return string
local function format_number_short(amount)
  local suffix = ""
  for _, data in ipairs(suffix_list) do
    if math.abs(amount) >= data[2] then
      amount = amount / data[2]
      suffix = data[1]
      break
    end
  end
  amount = math.floor(amount * 10) / 10

  local result = tostring(math.abs(math.floor(amount))) .. suffix
  if #result < 4 then
    result = "×" .. result
  end
  return result
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
--- @field entity_selector string
--- @field multiplier double?
--- @field source MeasureSource?
--- @field type_filter string?

--- @alias MeasureSource
--- | "materials"
--- | "power"
--- | "heat"

--- @type table<Measure, MeasureData>
local measure_data = {
  ["per-second"] = { multiplier = 1, entity_selector = "container" },
  ["per-minute"] = { multiplier = 60, entity_selector = "container" },
  ["per-hour"] = { multiplier = 60 * 60, entity_selector = "container" },
  ["transport-belts"] = { multiplier = 1 / 15, type_filter = "item", entity_selector = "transport-belt" },
  ["inserters"] = { type_filter = "item", entity_selector = "inserter" },
  ["power"] = { source = "power", type_filter = "entity" },
  ["heat"] = { source = "heat", type_filter = "entity" },
}

--- @param self Gui
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
  end
end

local gui = {}

local handlers = {}
handlers = {
  --- @param self Gui
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

  --- @param self Gui
  on_close_button_click = function(self)
    self.elems.rcalc_window.visible = false
    self.player.opened = nil
  end,

  --- @param self Gui
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

  --- @param self Gui
  on_search_button_click = function(self)
    toggle_search(self)
  end,

  --- @param self Gui
  --- @param e EventData.on_gui_selection_state_changed
  on_measure_dropdown_changed = function(self, e)
    local set = global.calculation_sets[self.player.index][self.current_set_index]
    if not set then
      return
    end
    local new_measure = ordered_measures[e.element.selected_index]
    set.selected_measure = new_measure
    gui.update(self.player)
  end,

  --- @param self Gui
  --- @param e EventData.on_gui_text_changed
  on_multiplier_textfield_changed = function(self, e)
    local set = global.calculation_sets[self.player.index][self.current_set_index]
    if not set then
      return
    end

    local new_value = tonumber(e.element.text)
    if not new_value or new_value == 0 then
      return
    end
    set.manual_multiplier = new_value
    gui.update(self.player)
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
--- @return GuiElemDef
local function table_with_label(name)
  return {
    type = "flow",
    direction = "vertical",
    { type = "label", style = "caption_label", caption = { "gui.rcalc-header-" .. name } },
    {
      type = "frame",
      style = "slot_button_deep_frame",
      {
        type = "table",
        name = name,
        style = "slot_table",
        style_mods = { minimal_width = 40 * 10, minimal_height = 40 },
        column_count = 10,
      },
    },
  }
end

--- @param player LuaPlayer
--- @param set_index uint?
--- @return Gui
function gui.build(player, set_index)
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
        style_mods = { top_margin = -2, bottom_margin = 1, width = 150 },
        visible = false,
        clear_and_focus_on_right_click = true,
        lose_focus_on_confirm = true,
      },
      {
        type = "sprite-button",
        name = "search_button",
        style = "frame_action_button",
        sprite = "utility/search_white",
        hovered_sprite = "utility/search_black",
        clicked_sprite = "utility/search_black",
        tooltip = { "gui.flib-search-instruction" },
        handler = { [defines.events.on_gui_click] = handlers.on_search_button_click },
      },
      {
        type = "sprite-button",
        style = "frame_action_button",
        sprite = "flib_pin_white",
        hovered_sprite = "flib_pin_black",
        clicked_sprite = "flib_pin_black",
        tooltip = { "gui.flib-keep-open" },
        handler = { [defines.events.on_gui_click] = handlers.on_pin_button_click },
      },
      {
        type = "sprite-button",
        name = "close_button",
        style = "frame_action_button",
        sprite = "utility/close_white",
        hovered_sprite = "utility/close_black",
        clicked_sprite = "utility/close_black",
        tooltip = { "gui.close-instruction" },
        handler = { [defines.events.on_gui_click] = handlers.on_close_button_click },
      },
    },
    {
      type = "frame",
      style = "inside_shallow_frame",
      direction = "vertical",
      {
        type = "frame",
        style = "subheader_frame",
        { type = "label", style = "subheader_caption_label", caption = "Measure:" },
        { type = "empty-widget", style = "flib_horizontal_pusher" },
        {
          type = "choose-elem-button",
          style = "rcalc_units_choose_elem_button",
          elem_type = "entity",
          elem_filters = {
            { filter = "type", type = "container" },
            { filter = "type", type = "logistic-container" },
            { filter = "type", type = "cargo-wagon" },
            { filter = "type", type = "storage-tank" },
            { filter = "type", type = "fluid-wagon" },
          },
          tooltip = { "gui.rcalc-capacity-divisor-description" },
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
          type = "textfield",
          name = "multiplier_textfield",
          style = "short_number_textfield",
          style_mods = { width = 40, horizontal_align = "center" },
          numeric = true,
          allow_decimal = true,
          tooltip = { "gui.rcalc-manual-multiplier-description" },
          text = "1",
          handler = { [defines.events.on_gui_text_changed] = handlers.on_multiplier_textfield_changed },
        },
      },
      {
        type = "flow",
        style_mods = { padding = 12, top_padding = 8 },
        direction = "vertical",
        table_with_label("products"),
        table_with_label("ingredients"),
        table_with_label("intermediates"),
        table_with_label("producers"),
        table_with_label("consumers"),
      },
    },
  })

  player.opened = elems.rcalc_window

  --- @type Gui
  local self = {
    current_set_index = set_index or #global.calculation_sets,
    elems = elems,
    player = player,
    pinned = false,
    search_open = false,
  }
  global.gui[player.index] = self

  gui.update(player)

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

--- @param player LuaPlayer
function gui.update(player)
  local self = gui.get(player)
  if not self then
    return
  end
  local elems = self.elems

  local player_sets = global.calculation_sets[self.player.index]
  if not player_sets then
    return
  end
  local set = player_sets[self.current_set_index]
  if not set then
    return
  end

  local measure = set.selected_measure
  local measure_suffix = { "gui.rcalc-measure-" .. measure .. "-suffix" }
  local measure_data = measure_data[measure]
  local multiplier = (measure_data.multiplier or 1) * set.manual_multiplier
  local type_filter = measure_data.type_filter

  self.elems.measure_dropdown.selected_index = flib_table.find(ordered_measures, measure) --[[@as uint]]

  for _, table in pairs({ elems.ingredients, elems.products, elems.intermediates, elems.producers, elems.consumers }) do
    table.clear()
  end

  local source = measure_data.source or "materials"
  for path, rates in pairs(set.rates[source] or {}) do
    if type_filter and rates.type ~= type_filter then
      goto continue
    end

    local prototype = game[rates.type .. "_prototypes"][rates.name]
    local table, style, amount, machines, tooltip
    if rates.output == 0 and rates.input > 0 then
      table = source == "materials" and elems.ingredients or elems.consumers
      style = "flib_slot_button_default"
      amount = rates.input * multiplier
      machines = rates.input_machines * set.manual_multiplier
      tooltip = {
        "gui.rcalc-slot-description",
        prototype.localised_name,
        flib_format.number(flib_math.round(amount, 0.01), source ~= "materials"),
        measure_suffix,
        flib_format.number(machines, true),
        flib_format.number(amount / machines, true),
      }
    elseif rates.output > 0 and rates.input == 0 then
      table = source == "materials" and elems.products or elems.producers
      style = "flib_slot_button_default"
      amount = rates.output * multiplier
      machines = rates.output_machines * set.manual_multiplier
      tooltip = {
        "gui.rcalc-slot-description",
        prototype.localised_name,
        flib_format.number(flib_math.round(amount, 0.01), source ~= "materials"),
        measure_suffix,
        flib_format.number(machines, true),
        flib_format.number(amount / machines, true),
      }
    else
      table = elems.intermediates -- We shouldn't ever get this for machines...
      amount = (rates.output - rates.input) * multiplier
      style = "flib_slot_button_default"
      machines = amount / ((rates.output * multiplier) / rates.output_machines) * set.manual_multiplier
      local net_machines_label
      if amount < 0 then
        style = "flib_slot_button_red"
        net_machines_label = { "gui.rcalc-machines-deficit" }
      else
        style = "flib_slot_button_green"
        net_machines_label = { "gui.rcalc-machines-surplus" }
      end
      tooltip = {
        "gui.rcalc-net-slot-description",
        prototype.localised_name,
        -- Net
        flib_format.number(flib_math.round(amount, 0.01), source ~= "materials"),
        measure_suffix,
        -- Output
        flib_format.number(flib_math.round((rates.output * multiplier), 0.01)),
        flib_format.number(rates.output_machines * set.manual_multiplier, true),
        flib_format.number((rates.output * multiplier) / (rates.output_machines * set.manual_multiplier), true),
        -- Input
        flib_format.number(flib_math.round((rates.input * multiplier), 0.01)),
        flib_format.number(rates.input_machines * set.manual_multiplier, true),
        flib_format.number((rates.input * multiplier) / (rates.input_machines * set.manual_multiplier), true),
        -- Net machines
        net_machines_label,
        flib_format.number(flib_math.round(math.abs(machines), 0.01)),
      }
    end

    flib_gui.add(table, {
      type = "sprite-button",
      name = path,
      style = style,
      sprite = path,
      number = flib_math.round(amount, 0.1),
      tooltip = tooltip,
      {
        type = "label",
        style = "count_label",
        style_mods = { width = 32, top_padding = 5, horizontal_align = "right" },
        caption = format_number_short(machines),
        ignored_by_interaction = true,
      },
    })

    ::continue::
  end

  for _, table in pairs({ elems.ingredients, elems.products, elems.intermediates, elems.producers, elems.consumers }) do
    if next(table.children) then
      table.parent.parent.visible = true
    else
      table.parent.parent.visible = false
    end
  end
end

--- @param player LuaPlayer
function gui.show_after_selection(player)
  local self = gui.get(player)
  if not self then
    return
  end
  self.current_set_index = #global.calculation_sets[player.index]
  gui.update(player)
  self.elems.rcalc_window.visible = true
  if not self.pinned then
    player.opened = self.elems.rcalc_window
  end
end

function gui.on_init()
  --- @type table<uint, Gui>
  global.gui = {}
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
