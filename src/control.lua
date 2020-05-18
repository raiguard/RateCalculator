local event = require("__flib__.event")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")

local global_data = require("scripts.global-data")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")
local selection_tool = require("scripts.selection-tool")

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  gui.init()

  global_data.init()
  for i, player in pairs(game.players) do
    player_data.init(i, player)
  end

  gui.build_lookup_tables()
end)

event.on_load(function()
  gui.build_lookup_tables()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    global_data.build_unit_data()
    for i, player in pairs(game.players) do
      player_data.refresh(player, global.players[i])
    end
  end
end)

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

event.on_player_selected_area(function(e)
  if e.item == "rcalc-selection-tool" then
    selection_tool.process_selection(e.player_index, e.area, e.entities, e.surface)
  end
end)

event.on_player_alt_selected_area(function(e)
  -- TODO cancel selection
end)