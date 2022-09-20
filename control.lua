local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local migration = require("__flib__.migration")
local on_tick_n = require("__flib__.on-tick-n")

local constants = require("__RateCalculator__.constants")

local global_data = require("__RateCalculator__.scripts.global-data")
local inserter_calc = require("__RateCalculator__.scripts.inserter-calc")
local migrations = require("__RateCalculator__.scripts.migrations")
local player_data = require("__RateCalculator__.scripts.player-data")
local selection_tool = require("__RateCalculator__.scripts.selection-tool")
local util = require("__RateCalculator__.scripts.util")

local selection_gui = require("__RateCalculator__.scripts.gui.index")

-- -----------------------------------------------------------------------------
-- FUNCTIONS

local function give_tool(player, player_table, measure)
  if not measure and util.is_rcalc_tool(player.cursor_stack) then
    if #player_table.selections > 0 then
      local SelectionGui = util.get_gui(player.index)
      if SelectionGui and not SelectionGui.state.visible then
        SelectionGui:open()
      end
    else
      util.error_flying_text(player, { "message.rcalc-select-first" })
    end
  elseif player.clear_cursor() then
    if not measure then
      measure = player_table.last_tool_measure
    end
    player.cursor_stack.set_stack({ name = "rcalc-" .. measure .. "-selection-tool", count = 1 })
    player.cursor_stack.label = constants.measures[measure].label
    player_table.last_tool_measure = measure
  end
end

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

-- BOOTSTRAP

event.on_init(function()
  on_tick_n.init()

  global_data.init()
  for i, player in pairs(game.players) do
    player_data.init(i)
    player_data.refresh(player, global.players[i])
  end
end)

event.on_load(function()
  for _, player_table in pairs(global.players) do
    local SelectionGui = player_table.gui
    if SelectionGui then
      selection_gui.load(SelectionGui)
    end
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
  give_tool(player, player_table)
end)

event.register("rcalc-next-measure", function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if util.is_rcalc_tool(player.cursor_stack) then
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
  if util.is_rcalc_tool(player.cursor_stack) then
    local prev_measure_index = constants.measures[player_table.last_tool_measure].index - 1
    if prev_measure_index == 0 then
      prev_measure_index = #constants.measures_arr
    end
    give_tool(player, player_table, constants.measures_arr[prev_measure_index])
  end
end)

event.register("rcalc-focus-search", function(e)
  local SelectionGui = util.get_gui(e.player_index)
  if SelectionGui and SelectionGui.state.visible and not SelectionGui.state.pinned then
    SelectionGui:dispatch("toggle_search", { player_index = e.player_index })
  end
end)

-- GUI

local function handle_gui_action(action, e)
  local SelectionGui = util.get_gui(e.player_index)
  if SelectionGui then
    SelectionGui:dispatch(action, e)
  end
end

gui.hook_events(function(e)
  local action = gui.read_action(e)
  if action then
    handle_gui_action(action, e)
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
  -- Update active language
  player.request_translation({ "locale-identifier" })
end)

event.on_player_removed(function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.iterating then
    -- Remove all render objects
    local objects = player_table.iteration_data.render_objects
    local destroy = rendering.destroy
    for i = 1, #objects do
      destroy(objects[i])
    end
  end
  global.players[e.player_index] = nil
end)

-- SELECTION TOOL

event.register({ defines.events.on_player_selected_area, defines.events.on_player_alt_selected_area }, function(e)
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
      util.error_flying_text(player, { "message.rcalc-select-one-inserter" })
      return
    end
    local inserter = entities[1]

    if inserter.valid then
      local rate, has_belt = inserter_calc(inserter)
      player_table.selected_inserter = {
        name = inserter.name,
        rate = rate,
      }
      local SelectionGui = util.get_gui(player.index)
      if SelectionGui then
        SelectionGui:update()
      end
      if has_belt then
        util.error_flying_text(player, { "message.rcalc-inserter-belt" })
      end
    end
  end
end)

-- SHORTCUT

event.on_lua_shortcut(function(e)
  if e.prototype_name == "rcalc-get-selection-tool" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    give_tool(player, player_table)
  end
end)

-- TICK

event.on_tick(function(e)
  local tasks = on_tick_n.retrieve(e.tick)
  if tasks then
    for _, task in pairs(tasks) do
      handle_gui_action(task.action, { player_index = task.player_index })
    end
  end

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
