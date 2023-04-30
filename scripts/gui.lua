local flib_gui = require("__flib__/gui-lite")
local flib_position = require("__flib__/position")
local flib_table = require("__flib__/table")

local gui_util = require("__RateCalculator__/scripts/gui-util")

--- @class GuiData
--- @field calc_set CalculationSet
--- @field elems table<string, LuaGuiElement>
--- @field inserter_divisor string
--- @field manual_multiplier double
--- @field materials_divisor string?
--- @field pinned boolean
--- @field player LuaPlayer
--- @field search_open boolean
--- @field search_query string
--- @field selected_timescale Timescale
--- @field transport_belt_divisor string

--- @type GuiLocation
local top_left_location = { x = 15, y = 58 + 15 }

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
    gui.reset_location(self)
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
    local timescale = self.selected_timescale
    local timescale_data = gui_util.timescale_data[timescale]
    if timescale_data.divisor_required and not entity_name then
      e.element.elem_value = self[timescale_data.divisor_source]
      return
    end
    self[timescale_data.divisor_source] = entity_name
    gui.update(self)
  end,

  --- @param self GuiData
  --- @param e EventData.on_gui_selection_state_changed
  on_timescale_dropdown_changed = function(self, e)
    local new_timescale = gui_util.ordered_timescales[e.element.selected_index]
    self.selected_timescale = new_timescale
    gui.update(self)
  end,

  --- @param self GuiData
  --- @param e EventData.on_gui_text_changed
  on_multiplier_textfield_changed = function(self, e)
    local text = e.text
    -- Don't prevent insertion of a decimal point
    if string.sub(text, #text) == "." then
      return
    end
    local new_value = tonumber(text)
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
      style = "rcalc_content_pane",
      style_mods = { minimal_width = 424 },
      direction = "vertical",
      {
        type = "frame",
        style = "subheader_frame",
        { type = "label", style = "subheader_caption_label", caption = { "gui.rcalc-timescale" } },
        { type = "empty-widget", style = "flib_horizontal_pusher" },
        {
          type = "choose-elem-button",
          name = "timescale_divisor_chooser",
          style = "rcalc_units_choose_elem_button",
          elem_type = "entity",
          tooltip = { "gui.rcalc-capacity-divisor-description" },
          handler = { [defines.events.on_gui_elem_changed] = handlers.on_divisor_elem_changed },
        },
        {
          type = "drop-down",
          name = "timescale_dropdown",
          items = flib_table.map(gui_util.ordered_timescales, function(timescale)
            return { "gui.rcalc-timescale-" .. timescale }
          end),
          handler = { [defines.events.on_gui_selection_state_changed] = handlers.on_timescale_dropdown_changed },
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
        name = "rates_scroll_pane",
        style = "rcalc_rates_scroll_pane",
        {
          type = "flow",
          name = "rates_flow",
          style_mods = { horizontal_spacing = 8 },
        },
      },
      {
        type = "flow",
        name = "no_rates_flow",
        style_mods = {
          horizontally_stretchable = true,
          height = 50,
          vertical_align = "center",
          horizontal_align = "center",
        },
        visible = false,
        { type = "label", caption = { "gui.rcalc-no-rates-to-display" } },
      },
      {
        type = "frame",
        name = "errors_frame",
        style = "rcalc_negative_subfooter_frame",
        direction = "vertical",
        visible = false,
      },
    },
  })

  player.opened = elems.rcalc_window

  --- @type GuiData
  local self = {
    elems = elems,
    inserter_divisor = gui_util.get_first_prototype(global.elem_filters.inserter_divisor),
    manual_multiplier = 1,
    pinned = false,
    player = player,
    search_open = false,
    search_query = "",
    selected_timescale = "per-second",
    transport_belt_divisor = gui_util.get_first_prototype(global.elem_filters.transport_belt_divisor),
  }
  global.gui[player.index] = self

  gui.reset_location(self)

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
  if not self.calc_set then
    return
  end

  local elems = self.elems

  local timescale = self.selected_timescale
  local timescale_data = gui_util.timescale_data[timescale]

  local timescale_divisor_chooser = elems.timescale_divisor_chooser
  local divisor_source = timescale_data.divisor_source
  if divisor_source then
    timescale_divisor_chooser.visible = true
    timescale_divisor_chooser.elem_filters = global.elem_filters[divisor_source]
    timescale_divisor_chooser.elem_value = self[divisor_source]
  else
    timescale_divisor_chooser.visible = false
  end
  elems.timescale_dropdown.selected_index = flib_table.find(gui_util.ordered_timescales, timescale) --[[@as uint]]
  elems.multiplier_textfield.text = tostring(self.manual_multiplier)

  self.calc_set.errors["inserter-rates-estimates"] = divisor_source == "inserter_divisor" and true or nil

  local suffix = { "gui.rcalc-timescale-suffix-" .. timescale }

  local ingredients, products, intermediates = gui_util.get_display_set(self, self.search_query)
  local rates_flow = self.elems.rates_flow
  rates_flow.clear()
  if ingredients then
    local show_machines = not products and not intermediates
    gui_util.build_rates_table(rates_flow, "ingredients", ingredients, show_machines, suffix)
  end
  if ingredients and (products or intermediates) then
    flib_gui.add(
      rates_flow,
      { type = "line", style_mods = { top_margin = -2, bottom_margin = -2 }, direction = "vertical" }
    )
  end
  if products or intermediates then
    local right_content_flow = rates_flow.add({ type = "flow", direction = "vertical" })
    if products then
      gui_util.build_rates_table(right_content_flow, "products", products, true, suffix)
      if intermediates then
        flib_gui.add(right_content_flow, {
          type = "line",
          style_mods = { left_margin = -4, right_margin = -4 },
          direction = "horizontal",
        })
      end
    end
    if intermediates then
      gui_util.build_rates_table(right_content_flow, "intermediates", intermediates, true, suffix)
    end
  end

  local rates_scroll_pane = self.elems.rates_scroll_pane
  if ingredients or products or intermediates then
    rates_scroll_pane.visible = true
  else
    rates_scroll_pane.visible = false
  end
  self.elems.no_rates_flow.visible = not ingredients and not products and not intermediates

  local errors_frame = self.elems.errors_frame
  errors_frame.clear()
  local visible = false
  if self.player.mod_settings["rcalc-show-calculation-errors"].value then
    for error in pairs(self.calc_set.errors) do
      visible = true
      errors_frame.add({
        type = "label",
        style = "bold_label",
        caption = { "", "[img=warning-white]  ", { "gui.rcalc-error-" .. error } },
        tooltip = { "?", { "gui.rcalc-error-" .. error .. "-description" }, "" },
      })
    end
  end
  errors_frame.visible = visible
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
  self.elems.rcalc_window.bring_to_front()
end

--- @param self GuiData
function gui.reset_location(self)
  local value = self.player.mod_settings["rcalc-default-gui-location"].value
  local window = self.elems.rcalc_window
  if value == "top-left" then
    local scale = self.player.display_scale
    window.location = flib_position.mul(top_left_location, { x = scale, y = scale })
  else
    window.auto_center = true
  end
end

function gui.on_init()
  --- @type table<uint, GuiData>
  global.gui = {}

  gui_util.build_divisor_filters()
  gui_util.build_dictionaries()
end

function gui.on_configuration_changed()
  gui_util.build_divisor_filters()
  gui_util.build_dictionaries()

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
  --- @param e EventData.on_runtime_mod_setting_changed
  [defines.events.on_runtime_mod_setting_changed] = function(e)
    if not string.match(e.setting, "^rcalc") then
      return
    end
    local player = game.get_player(e.player_index)
    if not player then
      return
    end
    local self = gui.get(player)
    if self then
      gui.update(self)
    end
    if e.setting == "rcalc-default-gui-location" then
      gui.reset_location(self)
    end
  end,
}

return gui
