local on_tick = {}

local event = require("__flib__.event")

local selection_tool = require("scripts.selection-tool")

function on_tick.handler()
  local players_to_iterate = global.players_to_iterate
  if next(players_to_iterate) then
    selection_tool.iterate(players_to_iterate)
  else
    event.on_tick(nil)
  end
end

function on_tick.register()
  if next(global.players_to_iterate) then
    event.on_tick(on_tick.handler)
  end
end

return on_tick