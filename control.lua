local handler = require("__core__.lualib.event_handler")

handler.add_libraries({
  require("scripts.migrations"),

  require("__flib__.dictionary"),
  require("__flib__.gui"),

  require("scripts.calc"),
  require("scripts.gui"),
  require("scripts.shortcut"),
})
