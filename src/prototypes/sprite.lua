local data_util = require("__flib__.data-util")

local frame_action_icons = "__RateCalculator__/graphics/frame-action-icons.png"

data:extend{
  data_util.build_sprite("rc_pin_black", {0, 0}, frame_action_icons, 32),
  data_util.build_sprite("rc_pin_white", {32, 0}, frame_action_icons, 32)
}
