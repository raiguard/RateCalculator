local data_util = require("__flib__.data-util")

local constants = require("constants")

data:extend{
  {
    type = "selection-tool",
    name = "rcalc-selection-tool",
    icons = {
      {icon = data_util.black_image, icon_size = 1, scale = 64},
      {icon = "__RateCalculator__/graphics/selection-tool.png", icon_size = 32, mipmap_count = 2}
    },
    selection_mode = {"any-entity", "same-force"},
    selection_color = constants.selection_color,
    selection_cursor_box_type = "entity",
    alt_selection_mode = {"any-entity", "same-force"},
    alt_selection_color = constants.alt_selection_color,
    alt_selection_cursor_box_type = "electricity",
    stack_size = 1,
    flags = {"hidden", "only-in-cursor", "not-stackable", "spawnable"}
  }
}