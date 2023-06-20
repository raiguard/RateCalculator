local flib_gui = require("__flib__/gui-lite")
local flib_position = require("__flib__/position")
local flib_table = require("__flib__/table")

local gui_rates = require("__RateCalculator__/scripts/gui-rates")
local gui_util = require("__RateCalculator__/scripts/gui-util")

--- @class GuiData
--- @field elems table<string, LuaGuiElement>
--- @field inserter_divisor string
--- @field manual_multiplier double
--- @field materials_divisor string?
--- @field pinned boolean
--- @field player LuaPlayer
--- @field search_open boolean
--- @field search_query string
--- @field selected_set_index integer
--- @field selected_timescale Timescale
--- @field sets CalculationSet[]
--- @field transport_belt_divisor string
--- @field display_data_lookup DisplayDataLookup

--- @type GuiLocation
local top_left_location = { x = 15, y = 58 + 15 }

--- @param self GuiData
local function reset_location(self)
  local value = self.player.mod_settings["rcalc-default-gui-location"].value
  local window = self.elems.rcalc_window
  if value == "top-left" then
    local scale = self.player.display_scale
    window.location = flib_position.mul(top_left_location, { scale, scale })
  else
    window.auto_center = true
  end
end

--- @param self GuiData
local function update_gui(self)
  local sets = self.sets
  local selected_set_index = self.selected_set_index
  local set = sets[selected_set_index]
  if not set then
    return
  end

  local elems = self.elems

  local nav_backward_button = elems.nav_backward_button
  local at_back = selected_set_index == 1
  nav_backward_button.sprite = at_back and "flib_nav_backward_disabled" or "flib_nav_backward_white"
  nav_backward_button.enabled = not at_back
  nav_backward_button.tooltip = { "gui.rcalc-previous-set", selected_set_index, #sets }

  local nav_forward_button = elems.nav_forward_button
  local at_front = selected_set_index == #sets
  nav_forward_button.sprite = at_front and "flib_nav_forward_disabled" or "flib_nav_forward_white"
  nav_forward_button.enabled = not at_front
  nav_forward_button.tooltip = { "gui.rcalc-next-set", selected_set_index, #sets }

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

  set.errors["inserter-rates-estimates"] = divisor_source == "inserter_divisor" and true or nil

  local show_checkboxes = self.player.mod_settings["rcalc-show-completion-checkboxes"].value --[[@as boolean]]
  local show_intermediate_breakdowns = self.player.mod_settings["rcalc-show-intermediate-breakdowns"].value --[[@as boolean]]
  self.elems.rates_scroll_pane.style.minimal_width = 500
    + (show_checkboxes and 44 or 0)
    + (show_intermediate_breakdowns and 50 or 0)

  local category_display_data = gui_rates.update_display_data(self, set)
  gui_rates.update_gui(self, category_display_data)

  local errors_frame = self.elems.errors_frame
  errors_frame.clear()
  local visible = false
  if self.player.mod_settings["rcalc-show-calculation-errors"].value then
    for error in pairs(set.errors) do
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
    update_gui(self)
  end
end

--- @param e EventData.on_gui_click
local function on_window_closed(e)
  local self = global.gui[e.player_index]
  if not self or self.pinned then
    return
  end
  if self.search_open then
    toggle_search(self)
    self.player.opened = self.elems.rcalc_window
    return
  end
  self.elems.rcalc_window.visible = false
end

--- @param e EventData.on_gui_click
local function on_titlebar_click(e)
  local self = global.gui[e.player_index]
  if not self or e.button ~= defines.mouse_button_type.middle then
    return
  end
  reset_location(self)
end

--- @param e EventData.on_gui_click
local function on_close_button_click(e)
  local self = global.gui[e.player_index]
  if not self then
    return
  end
  self.elems.rcalc_window.visible = false
  if self.player.opened == self.elems.rcalc_window then
    self.player.opened = nil
  end
end

--- @param e EventData.on_gui_click
local function on_pin_button_click(e)
  local self = global.gui[e.player_index]
  if not self then
    return
  end
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
end

--- @param e EventData.on_gui_click
local function on_nav_backward_button_click(e)
  local self = global.gui[e.player_index]
  if not self then
    return
  end
  self.selected_set_index = math.max(self.selected_set_index - 1, 1)
  update_gui(self)
end

--- @param e EventData.on_gui_click
local function on_nav_forward_button_click(e)
  local self = global.gui[e.player_index]
  if not self then
    return
  end
  self.selected_set_index = math.min(self.selected_set_index + 1, #self.sets)
  update_gui(self)
end

--- @param e EventData.on_gui_click
local function on_search_button_click(e)
  local self = global.gui[e.player_index]
  if not self then
    return
  end
  toggle_search(self)
end

--- @param e EventData.on_gui_text_changed
local function on_search_text_changed(e)
  local self = global.gui[e.player_index]
  if not self then
    return
  end
  self.search_query = string.lower(e.text)
  update_gui(self)
end

--- @param e EventData.on_gui_elem_changed
local function on_divisor_elem_changed(e)
  local self = global.gui[e.player_index]
  if not self then
    return
  end
  local entity_name = e.element.elem_value --[[@as string?]]
  local timescale = self.selected_timescale
  local timescale_data = gui_util.timescale_data[timescale]
  if timescale_data.divisor_required and not entity_name then
    e.element.elem_value = self[timescale_data.divisor_source]
    return
  end
  self[timescale_data.divisor_source] = entity_name
  update_gui(self)
end

--- @param e EventData.on_gui_selection_state_changed
local function on_timescale_dropdown_changed(e)
  local self = global.gui[e.player_index]
  if not self then
    return
  end
  local new_timescale = gui_util.ordered_timescales[e.element.selected_index]
  self.selected_timescale = new_timescale
  update_gui(self)
end

--- @param e EventData.on_gui_text_changed
local function on_multiplier_textfield_changed(e)
  local self = global.gui[e.player_index]
  if not self then
    return
  end
  local text = e.text
  -- Don't prevent insertion of a decimal point or zeroes
  local last_char = string.sub(text, #text)
  if last_char == "." or (string.match(text, "%.") and last_char == "0") then
    return
  end
  local new_value = tonumber(text)
  if not new_value or new_value == 0 then
    return
  end
  self.manual_multiplier = new_value
  update_gui(self)
end

--- @param e EventData.on_gui_click
local function on_multiplier_nudge_clicked(e)
  local self = global.gui[e.player_index]
  if not self then
    return
  end
  self.manual_multiplier = math.max(1, math.floor(self.manual_multiplier) + e.element.tags.delta)
  update_gui(self)
end

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
local function destroy_gui(player)
  local self = global.gui[player.index]
  if not self then
    return
  end
  global.gui[player.index] = nil
  local window = self.elems.rcalc_window
  if not window.valid then
    return
  end
  window.destroy()
end

--- @param player LuaPlayer
--- @return GuiData
local function build_gui(player)
  destroy_gui(player)

  local elems = flib_gui.add(player.gui.screen, {
    type = "frame",
    name = "rcalc_window",
    direction = "vertical",
    visible = false,
    handler = { [defines.events.on_gui_closed] = on_window_closed },
    {
      type = "flow",
      style = "flib_titlebar_flow",
      drag_target = "rcalc_window",
      handler = { [defines.events.on_gui_click] = on_titlebar_click },
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
        style = "flib_titlebar_search_textfield",
        visible = false,
        clear_and_focus_on_right_click = true,
        lose_focus_on_confirm = true,
        handler = { [defines.events.on_gui_text_changed] = on_search_text_changed },
      },
      frame_action_button("search_button", "utility/search", { "gui.flib-search-instruction" }, on_search_button_click),
      frame_action_button(
        "nav_backward_button",
        "flib_nav_backward",
        { "gui.rcalc-previous-set" },
        on_nav_backward_button_click
      ),
      frame_action_button(
        "nav_forward_button",
        "flib_nav_forward",
        { "gui.rcalc-next-set" },
        on_nav_forward_button_click
      ),
      frame_action_button("pin_button", "flib_pin", { "gui.flib-keep-open" }, on_pin_button_click),
      frame_action_button("close_button", "utility/close", { "gui.close-instruction" }, on_close_button_click),
    },
    {
      type = "frame",
      style = "inside_shallow_frame",
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
          handler = { [defines.events.on_gui_elem_changed] = on_divisor_elem_changed },
        },
        {
          type = "drop-down",
          name = "timescale_dropdown",
          items = flib_table.map(gui_util.ordered_timescales, function(timescale)
            return { "string-mod-setting.rcalc-default-timescale-" .. timescale }
          end),
          handler = { [defines.events.on_gui_selection_state_changed] = on_timescale_dropdown_changed },
        },
        { type = "label", caption = "[img=quantity-multiplier]" },
        {
          type = "flow",
          style = "rcalc_multiplier_holder_flow",
          {
            type = "textfield",
            name = "multiplier_textfield",
            style = "rcalc_multiplier_textfield",
            numeric = true,
            allow_decimal = true,
            clear_and_focus_on_right_click = true,
            lose_focus_on_confirm = true,
            tooltip = { "gui.rcalc-manual-multiplier-description" },
            text = "1",
            handler = { [defines.events.on_gui_text_changed] = on_multiplier_textfield_changed },
          },
          {
            type = "flow",
            style = "rcalc_multiplier_nudge_buttons_flow",
            direction = "vertical",
            {
              type = "sprite-button",
              style = "rcalc_multiplier_nudge_button",
              sprite = "rcalc_nudge_increase",
              tooltip = "+1",
              tags = { delta = 1 },
              handler = { [defines.events.on_gui_click] = on_multiplier_nudge_clicked },
            },
            {
              type = "sprite-button",
              style = "rcalc_multiplier_nudge_button",
              sprite = "rcalc_nudge_decrease",
              tooltip = "-1",
              tags = { delta = -1 },
              handler = { [defines.events.on_gui_click] = on_multiplier_nudge_clicked },
            },
          },
        },
      },
      {
        type = "scroll-pane",
        name = "rates_scroll_pane",
        style = "rcalc_rates_table_scroll_pane",
        { type = "flow", name = "rates_flow", style = "rcalc_rates_table_horizontal_flow" },
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

  local default_timescale = player.mod_settings["rcalc-default-timescale"].value --[[@as Timescale]]
  --- @type GuiData
  local self = {
    elems = elems,
    inserter_divisor = gui_util.get_first_prototype(global.elem_filters.inserter_divisor),
    manual_multiplier = 1,
    pinned = false,
    player = player,
    search_open = false,
    search_query = "",
    selected_timescale = default_timescale,
    sets = {},
    transport_belt_divisor = gui_util.get_first_prototype(global.elem_filters.transport_belt_divisor),
  }
  global.gui[player.index] = self

  reset_location(self)

  return self
end

--- @param e EventData.on_runtime_mod_setting_changed
local function on_runtime_mod_setting_changed(e)
  if not string.match(e.setting, "^rcalc") then
    return
  end
  local self = global.gui[e.player_index]
  if not self then
    return
  end
  update_gui(self)
  if e.setting == "rcalc-default-gui-location" then
    reset_location(self)
  end
end

--- @param e EventData.CustomInputEvent
local function on_linked_focus_search(e)
  local self = global.gui[e.player_index]
  if not self or not self.elems.rcalc_window.valid or self.pinned or not self.elems.rcalc_window.visible then
    return
  end
  toggle_search(self)
end

local gui = {}

--- @param player LuaPlayer
--- @return CalculationSet?
function gui.get_current_set(player)
  local self = global.gui[player.index]
  if self then
    return self.sets[self.selected_set_index]
  end
end

--- @param player LuaPlayer
--- @param set CalculationSet?
--- @param new_selection boolean?
function gui.build_and_show(player, set, new_selection)
  local self = global.gui[player.index]
  if not self or not self.elems.rcalc_window.valid then
    self = build_gui(player)
  end
  local sets = self.sets
  if set and (new_selection or not sets[1]) then
    sets[#sets + 1] = set
    if #sets > 10 then
      table.remove(sets, 1)
    end
    self.selected_set_index = #sets
  end
  if not sets[self.selected_set_index] then
    return
  end
  if new_selection then
    self.manual_multiplier = 1
  end
  gui.show(self)
end

--- @param self GuiData
function gui.show(self)
  update_gui(self)
  self.elems.rcalc_window.visible = true
  if not self.pinned then
    self.player.opened = self.elems.rcalc_window
  end
  self.elems.rcalc_window.bring_to_front()
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
    destroy_gui(player)
  end
end

gui.events = {
  [defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed,
  ["rcalc-linked-focus-search"] = on_linked_focus_search,
}

flib_gui.add_handlers({
  on_close_button_click = on_close_button_click,
  on_divisor_elem_changed = on_divisor_elem_changed,
  on_multiplier_nudge_clicked = on_multiplier_nudge_clicked,
  on_multiplier_textfield_changed = on_multiplier_textfield_changed,
  on_nav_backward_button_click = on_nav_backward_button_click,
  on_nav_forward_button_click = on_nav_forward_button_click,
  on_pin_button_click = on_pin_button_click,
  on_search_button_click = on_search_button_click,
  on_search_text_changed = on_search_text_changed,
  on_timescale_dropdown_changed = on_timescale_dropdown_changed,
  on_titlebar_click = on_titlebar_click,
  on_window_closed = on_window_closed,
})

return gui
