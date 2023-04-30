data:extend({
  {
    type = "shortcut",
    name = "rcalc-get-selection-tool",
    icon = {
      filename = "__RateCalculator__/graphics/shortcut-x32-black.png",
      size = 32,
      mipmap_count = 2,
      flags = { "gui-icon" },
    },
    disabled_icon = {
      filename = "__RateCalculator__/graphics/shortcut-x32-white.png",
      size = 32,
      mipmap_count = 2,
      flags = { "gui-icon" },
    },
    small_icon = {
      filename = "__RateCalculator__/graphics/shortcut-x24-black.png",
      size = 24,
      mipmap_count = 2,
      flags = { "gui-icon" },
    },
    disabled_small_icon = {
      filename = "__RateCalculator__/graphics/shortcut-x24-white.png",
      size = 24,
      mipmap_count = 2,
      flags = { "gui-icon" },
    },
    action = "lua",
    associated_control_input = "rcalc-get-selection-tool",
  },
})
