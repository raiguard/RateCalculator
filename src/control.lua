if __DebugAdapter then
  __DebugAdapter.defineGlobal("REGISTER_ON_TICK")
end

local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local migration = require("__flib__.migration")

local global_data = require("scripts.global-data")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")
local selection_tool = require("scripts.selection-tool")

local rates_gui = require("scripts.gui.rates")

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  global_data.init()
  for i, player in pairs(game.players) do
    player_data.init(i)
    player_data.refresh(player, global.players[i])
  end

  REGISTER_ON_TICK()
end)

event.on_load(function()
  REGISTER_ON_TICK()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    global_data.build_unit_data()
    global_data.update_settings()

    for i, player in pairs(game.players) do
      local player_table = global.players[i]
      if player_table.flags.iterating then
        selection_tool.stop_iteration(i, player_table)
      end
      player_data.refresh(player, player_table)
    end
  end
end)

-- GUI

gui.hook_events(function(e)
  local msg = gui.read_action(e)

  if msg then
    if msg.gui == "rates" then
      rates_gui.handle_action(e, msg)
    end
  end
end)

-- PLAYER

event.on_player_created(function(e)
  local player = game.get_player(e.player_index)
  player_data.init(e.player_index)
  player_data.refresh(player, global.players[e.player_index])
end)

event.on_player_joined_game(function(e)
  local player = game.get_player(e.player_index)
  -- update active language
  player.request_translation{"locale-identifier"}
end)

event.on_player_removed(function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.iterating then
    -- remove all render objects
    local objects = player_table.iteration_data.render_objects
    local destroy = rendering.destroy
    for i = 1, #objects do
      destroy(objects[i])
    end
  end
  global.players[e.player_index] = nil
end)

-- SELECTION TOOL

event.register({defines.events.on_player_selected_area, defines.events.on_player_alt_selected_area}, function(e)
  if e.item ~= "rcalc-selection-tool" then return end
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if player_table.flags.iterating then
    selection_tool.stop_iteration(e.player_index, player_table)
  end
  selection_tool.setup_selection(e, player, player_table)
end)

-- TICK

local function on_tick()
  local players_to_iterate = global.players_to_iterate
  if next(players_to_iterate) then
    selection_tool.iterate(players_to_iterate)
  else
    event.on_tick(nil)
  end
end

REGISTER_ON_TICK = function()
  if next(global.players_to_iterate) then
    event.on_tick(on_tick)
  end
end

-- TRANSLATIONS

event.on_string_translated(function(e)
  if e.translated and type(e.localised_string) == "table" and e.localised_string[1] == "locale-identifier" then
    local player_table = global.players[e.player_index]
    player_table.locale = e.result
  end
end)