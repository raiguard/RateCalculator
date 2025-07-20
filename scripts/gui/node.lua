local sw = require("__sw-rates-lib__.api-usage")

--- @class MainGui.Node : event_handler
--- @field parent MainGui
--- @field node MaterialNode
--- @field flow LuaGuiElement
local node_gui = {}
local mt = { __index = node_gui }
script.register_metatable("node_gui", mt)

--- @param parent MainGui
--- @param node MaterialNode
--- @return MainGui.Node
function node_gui.new(parent, node)
  local description = sw.node.gui_default(node.node)
  local button_desc = sw.gui.gui_button(description)
  local flow = parent.elems.content_pane.add({ type = "flow" })
  flow.style.vertical_align = "center"
  flow.add({
    type = "sprite-button",
    style = "transparent_slot",
    sprite = button_desc.sprite,
    quality = button_desc.quality and button_desc.quality.name or nil,
    elem_tooltip = button_desc.elem_tooltip,
    tooltip = button_desc.tooltip,
  })
  if next(node.output.configurations) then
    local output_desc = sw.gui.gui_button_and_text(description, node.output.amount)
    flow.add({ type = "label", caption = output_desc.text }).style.font_color = { r = 0.58, g = 1, b = 0.58 }
  end
  if next(node.input.configurations) then
    local input_desc = sw.gui.gui_button_and_text(description, node.input.amount)
    flow.add({ type = "label", caption = input_desc.text }).style.font_color = { r = 1, g = 0.58, b = 0.58 }
  end
  log(serpent.block(description))

  local self = {
    parent = parent,
    node = node,
    flow = flow,
  }
  setmetatable(self, mt)
  return self
end

return node_gui
