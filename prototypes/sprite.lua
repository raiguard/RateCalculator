local data_util = require("__flib__.data-util")

local frame_action_icons = "__RateCalculator__/graphics/frame-action-icons.png"

data:extend({
  data_util.build_sprite("rcalc_nav_backward_black", { 0, 0 }, frame_action_icons, 32),
  data_util.build_sprite("rcalc_nav_backward_white", { 32, 0 }, frame_action_icons, 32),
  data_util.build_sprite("rcalc_nav_backward_disabled", { 64, 0 }, frame_action_icons, 32),
  data_util.build_sprite("rcalc_nav_forward_black", { 0, 32 }, frame_action_icons, 32),
  data_util.build_sprite("rcalc_nav_forward_white", { 32, 32 }, frame_action_icons, 32),
  data_util.build_sprite("rcalc_nav_forward_disabled", { 64, 32 }, frame_action_icons, 32),
  data_util.build_sprite("rcalc_pin_black", { 0, 64 }, frame_action_icons, 32),
  data_util.build_sprite("rcalc_pin_white", { 32, 64 }, frame_action_icons, 32),
  data_util.build_sprite("rcalc_pin_disabled", { 64, 64 }, frame_action_icons, 32),
})
