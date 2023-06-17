local handler = require("__core__/lualib/event_handler")

handler.add_libraries({
  require("__RateCalculator__/scripts/migrations"),

  require("__flib__/dictionary-lite"),
  require("__flib__/gui-lite"),

  require("__RateCalculator__/scripts/calc"),
  require("__RateCalculator__/scripts/gui"),
  require("__RateCalculator__/scripts/shortcut"),
})
