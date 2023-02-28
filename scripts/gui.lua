local flib_format = require("__flib__/format")
local flib_math = require("__flib__/math")
local flib_gui = require("__flib__/gui-lite")

--- @class Gui
--- @field current_set_index integer
--- @field elems table<string, LuaGuiElement>
--- @field player LuaPlayer
--- @field pinned boolean
--- @field search_open boolean

local gui = {}

local handlers = {}
handlers = {
  --- @param self Gui
  on_window_closed = function(self)
    if self.pinned then
      return
    end
    if self.search_open then
      gui.toggle_search(self)
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
    local pinned = e.element.toggled
    e.element.sprite = pinned and "flib_pin_black" or "flib_pin_white"
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
    gui.toggle_search(self)
  end,
}

--- @param self Gui
function gui.toggle_search(self)
  local search_open = not self.search_open
  self.search_open = search_open
  local button = self.elems.search_button
  button.toggled = search_open
  button.sprite = search_open and "utility/search_black" or "utility/search_white"
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
        -- auto_toggle = true,
        handler = { [defines.events.on_gui_click] = handlers.on_search_button_click },
      },
      {
        type = "sprite-button",
        style = "frame_action_button",
        sprite = "flib_pin_white",
        hovered_sprite = "flib_pin_black",
        clicked_sprite = "flib_pin_black",
        tooltip = { "gui.flib-keep-open" },
        auto_toggle = true,
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
          items = { "Per second", "Per minute", "Per hour", "Transport belts", "Inserters" },
          selected_index = 2,
        },
        { type = "label", caption = "[img=quantity-multiplier]" },
        {
          type = "textfield",
          style = "short_number_textfield",
          style_mods = { width = 40, horizontal_align = "center" },
          tooltip = { "gui.rcalc-manual-multiplier-description" },
          text = "1",
        },
      },
      {
        type = "flow",
        style_mods = { padding = 12, top_padding = 8 },
        direction = "vertical",
        table_with_label("products"),
        table_with_label("ingredients"),
        table_with_label("intermediates"),
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

  local set = global.calculation_sets[self.player.index][self.current_set_index]
  if not set then
    return
  end

  for _, table in pairs({ elems.ingredients, elems.products, elems.intermediates }) do
    table.clear()
  end

  for path, rates in pairs(set.rates) do
    local prototype = game[rates.type .. "_prototypes"][rates.name]
    local table, style, amount, tooltip
    if rates.output == 0 and rates.input > 0 then
      table = elems.ingredients
      style = "flib_slot_button_default"
      amount = rates.input
      tooltip = {
        "gui.rcalc-slot-description",
        prototype.localised_name,
        flib_format.number(flib_math.round(amount * 60, 0.01)),
        "m",
        flib_format.number(rates.input_machines, true),
        flib_format.number(amount * 60 / rates.input_machines, true),
      }
    elseif rates.output > 0 and rates.input == 0 then
      table = elems.products
      style = "flib_slot_button_default"
      amount = rates.output
      tooltip = {
        "gui.rcalc-slot-description",
        prototype.localised_name,
        flib_format.number(flib_math.round(amount * 60, 0.01)),
        "m",
        flib_format.number(rates.output_machines, true),
        flib_format.number(amount * 60 / rates.output_machines, true),
      }
    else
      table = elems.intermediates
      amount = rates.output - rates.input
      style = "flib_slot_button_default"
      local net_machines_label
      if amount < 0 then
        style = "flib_slot_button_red"
        net_machines_label = { "gui.rcalc-machines-defecit" }
      else
        style = "flib_slot_button_green"
        net_machines_label = { "gui.rcalc-machines-surplus" }
      end
      tooltip = {
        "gui.rcalc-net-slot-description",
        prototype.localised_name,
        -- Net
        flib_format.number(flib_math.round(amount * 60, 0.01)),
        "m",
        -- Output
        flib_format.number(flib_math.round(rates.output * 60, 0.01)),
        flib_format.number(rates.output_machines, true),
        flib_format.number(rates.output * 60 / rates.output_machines, true),
        -- Input
        flib_format.number(flib_math.round(rates.input * 60, 0.01)),
        flib_format.number(rates.input_machines, true),
        flib_format.number(rates.input * 60 / rates.input_machines, true),
        -- Net machines
        net_machines_label,
        flib_format.number(
          flib_math.round(math.abs((amount * 60) / (rates.output * 60) / rates.output_machines), 0.01)
        ),
      }
    end
    flib_gui.add(table, {
      type = "sprite-button",
      name = path,
      style = style,
      sprite = path,
      number = flib_math.round(amount * 60, 0.1),
      tooltip = tooltip,
    })
  end

  for _, table in pairs({ elems.ingredients, elems.products, elems.intermediates }) do
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
    if not self or player.opened ~= self.elems.rcalc_window then
      return
    end
    gui.toggle_search(self)
  end,
}

return gui
