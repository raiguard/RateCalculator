local shortcut_sheet = "__RateCalculator__/graphics/shortcut.png"

data:extend({
  {
    type = "shortcut",
    name = "rcalc-get-selection-tool",
    icon = {
      filename = shortcut_sheet,
      position = { 0, 0 },
      size = 32,
      mipmap_count = 2,
      flags = { "gui-icon" },
    },
    disabled_icon = {
      filename = shortcut_sheet,
      position = { 48, 0 },
      size = 32,
      mipmap_count = 2,
      flags = { "gui-icon" },
    },
    small_icon = {
      filename = shortcut_sheet,
      position = { 0, 32 },
      size = 24,
      mipmap_count = 2,
      flags = { "gui-icon" },
    },
    disabled_small_icon = {
      filename = shortcut_sheet,
      position = { 36, 32 },
      size = 24,
      mipmap_count = 2,
      flags = { "gui-icon" },
    },
    action = "lua",
    associated_control_input = "rcalc-get-selection-tool",
  },
})
