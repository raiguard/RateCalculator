local on_tick = {}

local event = require("__flib__.event")

local selection_tool = require("scripts.selection-tool")

function on_tick.handler(e)
  local players_to_iterate = global.players_to_iterate
  local players_to_iterate_len = #players_to_iterate
  if players_to_iterate_len > 0 then
    selection_tool.iterate(players_to_iterate, players_to_iterate_len, e.tick)
  else
    event.on_tick(nil)
  end
end

function on_tick.update()
  if #global.players_to_iterate > 0 then
    event.on_tick(on_tick.handler)
  else
    event.on_tick(nil)
  end
end

return on_tick