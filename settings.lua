data:extend({
  {
    type = "bool-setting",
    name = "rcalc-dismiss-tool-on-selection",
    setting_type = "runtime-per-user",
    default_value = false,
  },
  {
    type = "bool-setting",
    name = "rcalc-show-calculation-errors",
    setting_type = "runtime-per-user",
    default_value = true,
  },
  {
    type = "bool-setting",
    name = "rcalc-show-power-consumption",
    setting_type = "runtime-per-user",
    default_value = false,
  },
  {
    type = "string-setting",
    name = "rcalc-default-gui-location",
    setting_type = "runtime-per-user",
    default_value = "top-left",
    allowed_values = { "top-left", "center" },
  },
})
