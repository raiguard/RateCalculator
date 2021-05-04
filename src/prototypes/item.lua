local data_util = require("__flib__.data-util")
local table = require("__flib__.table")

local constants = require("constants")

local selection_tool_base = {
  type = "selection-tool",
  localised_name = {"item-name.rcalc-selection-tool"},
  icons = {
    {icon = data_util.black_image, icon_size = 1, scale = 64},
    {icon = "__RateCalculator__/graphics/selection-tool.png", icon_size = 32, mipmap_count = 2}
  },
  selection_mode = {"buildable-type", "friend", "trees"},
  alt_selection_mode = {"buildable-type", "friend", "trees"},
  stack_size = 1,
  flags = {"hidden", "only-in-cursor", "not-stackable"},
  draw_label_for_cursor_render = true
}

local selection_tools = {}

for measure, data in pairs(constants.measures) do
  local tool = table.deep_copy(selection_tool_base)
  tool.name = "rcalc-"..measure.."-selection-tool"
  tool.selection_color = data.color
  tool.selection_cursor_box_type = data.selection_box
  local alt_color = table.shallow_copy(data.color)
  -- temporary?
  alt_color.b = 0.7
  tool.alt_selection_color = alt_color
  tool.alt_selection_cursor_box_type = data.selection_box
  selection_tools[#selection_tools+1] = tool
end

data:extend(selection_tools)

data:extend{
  {
    type = "selection-tool",
    name = "rcalc-inserter-selector",
    icons = {
      {icon = data_util.black_image, icon_size = 1, scale = 64},
      {icon = "__RateCalculator__/graphics/inserter-selection-tool.png", icon_size = 32, mipmap_count = 2}
    },
    selection_color = {r = 1, g = 1},
    alt_selection_color = {r = 1, g = 1},
    selection_cursor_box_type = "entity",
    alt_selection_cursor_box_type = "entity",
    selection_mode = {"buildable-type", "friend"},
    alt_selection_mode = {"buildable-type", "friend"},
    entity_type_filters = {"inserter"},
    alt_entity_type_filters = {"inserter"},
    stack_size = 1,
    flags = {"hidden", "only-in-cursor", "not-stackable"},
    draw_label_for_cursor_render = true
  }
}
