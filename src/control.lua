local event = require("__flib__.event")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")

local global_data = require("scripts.global-data")
local migrations = require("scripts.migrations")
local on_tick = require("scripts.on-tick")
local player_data = require("scripts.player-data")
local selection_tool = require("scripts.selection-tool")

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS
-- on_tick handler is kept in scripts.on-tick

-- BOOTSTRAP

event.on_init(function()
  gui.init()

  global_data.init()
  for i, player in pairs(game.players) do
    player_data.init(i, player)
  end

  on_tick.update()

  gui.build_lookup_tables()
end)

event.on_load(function()
  on_tick.update()

  gui.build_lookup_tables()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    global_data.build_unit_data()
    global_data.update_settings()
    for i, player in pairs(game.players) do
      player_data.refresh(player, global.players[i])
    end
  end
end)

-- TODO print a warning if research changes / finished during iteration

-- GUI

gui.register_handlers()

-- PLAYER

event.on_player_created(function(e)
  player_data.init(e.player_index, game.get_player(e.player_index))
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

-- SELECTION TOOL

event.register({defines.events.on_player_selected_area, defines.events.on_player_alt_selected_area}, function(e)
  if e.item ~= "rcalc-selection-tool" then return end
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if player_table.flags.iterating then
    player_data.stop_iteration(e.player_index, player_table)
  end
  selection_tool.setup_selection(player, player_table, e.area, e.entities, e.surface)
  on_tick.update()
end)