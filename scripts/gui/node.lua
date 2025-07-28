local flib_format = require("__flib__.format")

local sw = require("__sw-rates-lib__.api-usage")

-- TODO: Timescale drop-down
--- @param amount number
--- @param format Rates.Node.NumberFormat
--- @return LocalisedString
local function format_rate(amount, format)
  amount = amount * format.factor
  local unit = format.unit
  if unit == "/h" then
    amount = amount / (60 * 60)
    unit = "/s"
  elseif unit == "/m" then
    amount = amount / 60
    unit = "/s"
  end

  -- TODO: Use a LocalisedString with properly localised suffixes and delimiters
  return flib_format.number(amount, true, 5) .. unit
end

--- @class MainGui.Node : event_handler
--- @field main_gui MainGui
--- @field node MaterialNode
--- @field flow LuaGuiElement
local node_gui = {}
local mt = { __index = node_gui }
script.register_metatable("node_gui", mt)

local green = { r = 0.58, g = 1, b = 0.58 }
local red = { r = 1, g = 0.58, b = 0.58 }

--- @param main_gui MainGui
--- @param parent LuaGuiElement
--- @param node MaterialNode
--- @return MainGui.Node
function node_gui.new(main_gui, parent, node)
  local description = sw.node.gui_default(node.node)
  local button_desc = sw.gui.gui_button(description)
  local flow = parent.add({ type = "flow", style = "player_input_horizontal_flow" })
  flow.style.vertical_align = "center"
  local button_holder = flow.add({ type = "empty-widget" })
  button_holder.style.size = 40
  button_holder.add({
    type = "sprite-button",
    style = "flib_standalone_slot_button_default",
    sprite = button_desc.sprite,
    quality = button_desc.quality and button_desc.quality.name or nil,
    elem_tooltip = button_desc.elem_tooltip,
    tooltip = button_desc.tooltip,
  })
  if description.qualifier then
    local qualifier_label =
      button_holder.add({ type = "label", style = "rcalc_qualifier_label", caption = description.qualifier })
    qualifier_label.style.left_padding = 2
    qualifier_label.style.top_padding = -2
  end
  local text_holder = flow
  if node:get_gui_category() == "intermediate" then
    local intermediate_flow = flow.add({ type = "flow", style = "packed_vertical_flow", direction = "vertical" })
    text_holder = intermediate_flow.add({ type = "flow", style = "player_input_horizontal_flow" })
    intermediate_flow.style.top_margin = -3

    local net_rate = node.output.amount + node.input.amount
    local net_rate_label = intermediate_flow.add({
      type = "label",
      style = "semibold_label",
      caption = {
        "",
        "= ",
        net_rate > 0 and "+" or "",
        format_rate(net_rate, description.number_format or { factor = 1, unit = "/s" }),
      },
    })
    net_rate_label.style.top_margin = -6
    if net_rate > 0 then
      net_rate_label.style.font_color = green
    elseif net_rate < 0 then
      net_rate_label.style.font_color = red
    end
  end
  if next(node.output.configurations) then
    local text = format_rate(node.output.amount, description.number_format or { factor = 1, unit = "/s" })
    local label = text_holder.add({ type = "label", style = "semibold_label", caption = text })
    label.style.font_color = green
  end
  if next(node.input.configurations) then
    local text = format_rate(node.input.amount, description.number_format or { factor = 1, unit = "/s" })
    local label = text_holder.add({ type = "label", style = "semibold_label", caption = text })
    label.style.font_color = red
  end
  log(serpent.block(description))

  local self = {
    main_gui = main_gui,
    node = node,
    flow = flow,
  }
  setmetatable(self, mt)
  return self
end

return node_gui
