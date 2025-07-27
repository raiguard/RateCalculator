local flib_table = require("__flib__.table")

local node_gui = require("scripts.gui.node")

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

--- @alias MainGui.CategorizedNodes table<MaterialNode.GuiCategory, string[]?>

--- @class MainGui.Elems
--- @field window LuaGuiElement
--- @field titlebar_flow LuaGuiElement
--- @field close_button LuaGuiElement
--- @field pin_button LuaGuiElement
--- @field content_pane LuaGuiElement
--- @field ingredient_flow LuaGuiElement
--- @field ingredient_separator_line LuaGuiElement
--- @field product_flow LuaGuiElement
--- @field product_separator_line LuaGuiElement
--- @field intermediate_flow LuaGuiElement

--- @class MainGui : event_handler
--- @field elems MainGui.Elems
--- @field player LuaPlayer
--- @field categorized_nodes MainGui.CategorizedNodes
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

  local content_pane = window
    .add({ type = "frame", style = "inside_shallow_frame", direction = "vertical" })
    .add({ type = "scroll-pane", style = "flib_naked_scroll_pane" })

  local content_flow = content_pane.add({ type = "flow", direction = "horizontal" })
  content_flow.style.horizontal_spacing = 8

  -- TODO: Make a subclass to contain these
  local ingredient_flow = content_flow.add({ type = "flow", direction = "vertical" })
  local ingredient_separator_line = content_flow.add({ type = "line", direction = "vertical" })
  local right_column_flow = content_flow.add({ type = "flow", direction = "vertical" })
  right_column_flow.style.vertical_spacing = 8
  local product_flow = right_column_flow.add({ type = "flow", direction = "vertical" })
  local product_separator_line = right_column_flow.add({ type = "line", direction = "horizontal" })
  local intermediate_flow = right_column_flow.add({ type = "flow", direction = "vertical" })

  --- @type MainGui
  local self = {
    elems = {
      window = window,
      titlebar_flow = titlebar_flow,
      pin_button = pin_button,
      close_button = close_button,
      content_pane = content_pane,
      ingredient_flow = ingredient_flow,
      ingredient_separator_line = ingredient_separator_line,
      product_flow = product_flow,
      product_separator_line = product_separator_line,
      intermediate_flow = intermediate_flow,
    },
    player = player,
    categorized_nodes = {},
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
  self:update()
  self:show()
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

function main_gui:update()
  local set = storage.rates_set_manager:get_active(self.player.index)
  if not set then
    return
  end

  -- TODO: Don't do this unless the set is changed.
  --- @type MainGui.CategorizedNodes
  local categorized_nodes = {}
  for node_id, node in pairs(set.nodes) do
    local category = node:get_gui_category()
    if not categorized_nodes[category] then
      categorized_nodes[category] = {}
    end
    table.insert(categorized_nodes[category], node_id)
  end

  for _, category in pairs(categorized_nodes) do
    table.sort(category, function(a_id, b_id)
      local a = set:get_node(a_id)
      local b = set:get_node(b_id)
      return a:get_sorting_value() < b:get_sorting_value()
    end)
  end

  --- @param parent LuaGuiElement
  --- @param category_name MaterialNode.GuiCategory
  local function add_category(parent, category_name)
    parent.clear()
    local category_nodes = categorized_nodes[category_name]
    if not category_nodes then
      parent.visible = false
      return
    end
    parent.visible = true
    parent.add({ type = "label", style = "caption_label", caption = { "gui.rcalc-category-header-" .. category_name } })
    for _, node_id in pairs(category_nodes) do
      local node = set:get_node(node_id)
      -- TODO: Pass the node ID instead of the node!
      node_gui.new(self, parent, node)
    end
  end

  local has_ingredients = categorized_nodes.ingredient ~= nil
  local has_products = categorized_nodes.product ~= nil
  local has_intermediates = categorized_nodes.intermediate ~= nil

  self.elems.ingredient_separator_line.visible = has_ingredients and (has_products or has_intermediates)
  self.elems.product_separator_line.visible = has_products and has_intermediates

  add_category(self.elems.ingredient_flow, "ingredient")
  add_category(self.elems.product_flow, "product")
  add_category(self.elems.intermediate_flow, "intermediate")

  -- self.categorized_nodes = categorized_nodes
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
