local event = require("__flib__.event")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")

local global_data = require("scripts.global-data")
local migrations = require("scripts.migrations")
local on_tick = require("scripts.on-tick")
local player_data = require("scripts.player-data")
local rcalc_gui = require("scripts.gui")
local selection_tool = require("scripts.selection-tool")

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS
-- on_tick handler is kept in scripts.on-tick

-- BOOTSTRAP

event.on_init(function()
  gui.init()
  gui.build_lookup_tables()

  global_data.init()
  for i, player in pairs(game.players) do
    player_data.init(i, player)
    rcalc_gui.create(player, global.players[i])
  end

  on_tick.register()
end)

event.on_load(function()
  on_tick.register()

  gui.build_lookup_tables()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    gui.check_filter_validity()

    global_data.build_unit_data()
    global_data.update_settings()

    for i, player in pairs(game.players) do
      local player_table = global.players[i]
      if player_table.flags.iterating then
        selection_tool.stop_iteration(i, player_table)
      end
      rcalc_gui.destroy(player, player_table)
      player_data.refresh(player, player_table)
      rcalc_gui.create(player, player_table)
    end
  end
end)

-- GUI

gui.register_handlers()

-- PLAYER

event.on_player_created(function(e)
  local player = game.get_player(e.player_index)
  player_data.init(e.player_index, player)
  rcalc_gui.create(player, global.players[e.player_index])
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
  if selection_tool.setup_selection(player, player_table, e.area, e.entities, e.surface) then
    on_tick.register()
  end
end)