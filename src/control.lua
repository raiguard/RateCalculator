local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local migration = require("__flib__.migration")

local constants = require("constants")

local global_data = require("scripts.global-data")
local inserter_calc = require("scripts.inserter-calc")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")
local selection_tool = require("scripts.selection-tool")

local selection_gui = require("scripts.gui.selection")

-- -----------------------------------------------------------------------------
-- FUNCTIONS

local function is_rcalc_tool(cursor_stack)
  return cursor_stack and cursor_stack.valid_for_read and string.find(cursor_stack.name, "rcalc%-(.+)%-selection%-tool")
end

local function give_tool(player, player_table, measure)
  if player.clear_cursor() then
    player.cursor_stack.set_stack{name = "rcalc-"..measure.."-selection-tool", count = 1}
    player.cursor_stack.label = constants.measures[measure].label
    player_table.last_tool_measure = measure
  end
end

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  global_data.init()
  for i, player in pairs(game.players) do
    player_data.init(i)
    player_data.refresh(player, global.players[i])
  end
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    global_data.build_entity_rates()
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

-- CUSTOM INPUT

event.register("rcalc-get-selection-tool", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  give_tool(player, player_table, player_table.last_tool_measure)
end)

event.register("rcalc-next-measure", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if is_rcalc_tool(player.cursor_stack) then
    give_tool(
      player,
      player_table,
      next(constants.measures, player_table.last_tool_measure) or next(constants.measures)
    )
  end
end)

event.register("rcalc-previous-measure", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if is_rcalc_tool(player.cursor_stack) then
    local prev_measure_index = constants.measures[player_table.last_tool_measure].index - 1
    if prev_measure_index == 0 then
      prev_measure_index = #constants.measures_arr
    end
    give_tool(player, player_table, constants.measures_arr[prev_measure_index])
  end
end)

event.register("rcalc-focus-search", function(e)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.guis.selection
  if gui_data and gui_data.state.visible and not gui_data.state.pinned then
    selection_gui.handle_action({player_index = e.player_index}, {action = "toggle_search"})
  end
end)

-- GUI

gui.hook_events(function(e)
  local msg = gui.read_action(e)

  if msg then
    if msg.gui == "selection" then
      selection_gui.handle_action(e, msg)
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
  local is_tool, _, tool_measure = string.find(e.item, "rcalc%-(.+)%-selection%-tool")
  if is_tool then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    if player_table.flags.iterating then
      selection_tool.stop_iteration(e.player_index, player_table)
    end
    selection_tool.setup_selection(
      e,
      player,
      player_table,
      tool_measure,
      e.name == defines.events.on_player_alt_selected_area
    )
  elseif e.item == "rcalc-inserter-selector" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    local entities = e.entities
    if #entities ~= 1 then
      player.create_local_flying_text{
        text = {"gui.rcalc-select-one-inserter"},
        create_at_cursor = true
      }
      player.play_sound{path = "utility/cannot_build"}
      return
    end
    local inserter = entities[1]

    if inserter.valid then
      player_table.selected_inserter = {
        name = inserter.name,
        rate = inserter_calc(inserter)
      }
      local gui_data = player_table.guis.selection
      if gui_data and gui_data.state.visible then
        selection_gui.update(player_table)
      end
    end
  end
end)

-- SETTINGS

event.on_runtime_mod_setting_changed(function(e)
  if e.setting == "rcalc-rates-table-rows" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    selection_gui.update_table_rows(player, player_table)
  end
end)

-- SHORTCUT

event.on_lua_shortcut(function(e)
  if e.prototype_name == "rcalc-get-selection-tool" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    give_tool(player, player_table, player_table.last_tool_measure)
  end
end)

-- TICK

event.on_tick(function()
  local players_to_iterate = global.players_to_iterate
  if next(players_to_iterate) then
    selection_tool.iterate(players_to_iterate)
  end
end)

-- TRANSLATIONS

event.on_string_translated(function(e)
  if e.translated and type(e.localised_string) == "table" and e.localised_string[1] == "locale-identifier" then
    local player_table = global.players[e.player_index]
    player_table.locale = e.result
  end
end)
