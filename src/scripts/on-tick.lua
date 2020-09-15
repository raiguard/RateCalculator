local on_tick = {}

local event = require("__flib__.event")

local selection_tool = require("scripts.selection-tool")

function on_tick.handler()
  local players_to_iterate = global.players_to_iterate
  local players_to_iterate_len = #players_to_iterate
  if players_to_iterate_len > 0 then
    selection_tool.iterate(players_to_iterate, players_to_iterate_len)
  else
    event.on_tick(nil)
  end
end

function on_tick.register()
  if #global.players_to_iterate > 0 then
    event.on_tick(on_tick.handler)
  end
end

return on_tick