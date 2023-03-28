local handler = require("__core__/lualib/event_handler")

handler.add_lib(require("__flib__/dictionary-lite"))
handler.add_lib(require("__flib__/gui-lite"))

handler.add_lib(require("__RateCalculator__/scripts/migrations"))

handler.add_lib(require("__RateCalculator__/scripts/gui"))
handler.add_lib(require("__RateCalculator__/scripts/selection"))
handler.add_lib(require("__RateCalculator__/scripts/shortcut"))
