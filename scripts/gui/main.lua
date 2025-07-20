--- @param sprite SpritePath
--- @param tooltip LocalisedString
--- @param auto_toggle boolean?
--- @return LuaGuiElement.add_param.sprite_button
local function frame_action_button(sprite, tooltip, auto_toggle)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite,
    tooltip = tooltip,
    mouse_button_filter = { "left" },
    auto_toggle = auto_toggle,
  }
end

--- @class MainGuiElems
--- @field window LuaGuiElement
--- @field titlebar_flow LuaGuiElement
--- @field close_button LuaGuiElement
--- @field pin_button LuaGuiElement

--- @class MainGui : event_handler
--- @field elems MainGuiElems
--- @field player LuaPlayer
local main_gui = {}
local mt = { __index = main_gui }
script.register_metatable("main_gui", mt)

--- @param player LuaPlayer
function main_gui.new(player)
  local window =
    player.gui.screen.add({ type = "frame", name = "rcalc_main_window", direction = "vertical", visible = false })
  window.force_auto_center()

  local titlebar_flow = window.add({ type = "flow", style = "flib_titlebar_flow" })
  titlebar_flow.drag_target = window
  titlebar_flow.add({
    type = "label",
    style = "flib_frame_title",
    caption = { "gui.rcalc-main-gui-title" },
    ignored_by_interaction = true,
  })
  titlebar_flow.add({ type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true })
  local pin_button = titlebar_flow.add(frame_action_button("flib_pin_white", { "gui.flib-keep-open" }, true))
  local close_button = titlebar_flow.add(frame_action_button("utility/close", { "gui.close-instruction" }))

  --- @type MainGui
  local self = {
    elems = {
      window = window,
      titlebar_flow = titlebar_flow,
      pin_button = pin_button,
      close_button = close_button,
    },
    player = player,
  }
  setmetatable(self, mt)
  storage.gui[player.index] = self
  return self
end

--- @param player LuaPlayer
function main_gui.build_and_show(player)
  local self = storage.gui[player.index]
  if not self or not self.elems.window.valid then
    self = main_gui.new(player)
  end
  self:show()
  -- local sets = self.sets
  -- if set and (new_selection or not sets[1]) then
  --   sets[#sets + 1] = set
  --   if #sets > 10 then
  --     table.remove(sets, 1)
  --   end
  --   self.selected_set_index = #sets
  -- end
  -- if not sets[self.selected_set_index] then
  --   return
  -- end
  -- if new_selection then
  --   self.manual_multiplier = 1
  -- end
  -- gui.show(self)
end

--- @param player LuaPlayer
function main_gui.show_if_valid(player)
  local self = storage.gui[player.index]
  if not self then
    return
  end
  if not self.elems.window.valid then
    self = main_gui.new(player)
  end
  self:show()
end

function main_gui:show()
  self.elems.window.visible = true
  if not self:is_pinned() then
    self.player.opened = self.elems.window
  end
end

function main_gui:hide()
  self.elems.window.visible = false
  if self.player.opened == self.elems.window then
    self.player.opened = nil
  end
end

--- @return boolean
function main_gui:is_pinned()
  return self.elems.pin_button.toggled
end

function main_gui:toggle_pinned()
  local to_state = self.elems.pin_button.toggled
  if to_state then
    self.player.opened = nil
  else
    self.player.opened = self.elems.window
    self.elems.window.force_auto_center()
  end
end

-- Event handlers

function main_gui.on_init()
  --- @type table<uint, MainGui>
  storage.gui = {}
end

function main_gui.on_configuration_changed()
  -- TODO:
end

--- @param e EventData.on_gui_click
local function on_gui_click(e)
  local self = storage.gui[e.player_index]
  if not self then
    return
  end

  local elem = e.element
  if elem == self.elems.titlebar_flow and e.button == defines.mouse_button_type.middle then
    self.elems.window.force_auto_center()
  elseif elem == self.elems.close_button then
    self:hide()
  elseif elem == self.elems.pin_button then
    self:toggle_pinned()
  end
end

--- @param e EventData.on_gui_closed
local function on_gui_closed(e)
  local self = storage.gui[e.player_index]
  if not self then
    return
  end

  local elem = e.element
  if elem == self.elems.window and not self:is_pinned() then
    self:hide()
  end
end

main_gui.events = {
  [defines.events.on_gui_click] = on_gui_click,
  [defines.events.on_gui_closed] = on_gui_closed,
}

return main_gui
