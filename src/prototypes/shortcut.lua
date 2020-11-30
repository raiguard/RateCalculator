local data_util = require("__flib__.data-util")

local shortcut_sheet = "__RateCalculator__/graphics/shortcut.png"

data:extend{
  {
    type = "shortcut",
    name = "rcalc-get-selection-tool",
    icon = data_util.build_sprite(nil, {0,0}, shortcut_sheet, 32, 2),
    disabled_icon = data_util.build_sprite(nil, {48,0}, shortcut_sheet, 32, 2),
    small_icon = data_util.build_sprite(nil, {0,32}, shortcut_sheet, 24, 2),
    disabled_small_icon = data_util.build_sprite(nil, {36,32}, shortcut_sheet, 24, 2),
    associated_control_input = "rcalc-get-selection-tool",
    action = "lua"
  }
}