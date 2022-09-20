local util = require("__RateCalculator__.scripts.util")

local player_data = {}

local selection_gui = require("__RateCalculator__.scripts.gui.index")

function player_data.init(index)
  --- @class PlayerTable
  global.players[index] = {
    flags = {
      iterating = false,
    },
    --- @type SelectionGui?
    gui = nil,
    --- @type IterationData?
    iteration_data = nil,
    last_tool_measure = "all",
    selected_inserter = nil,
    selections = {},
  }
end

function player_data.refresh(player, player_table)
  -- Update active language
  player.request_translation({ "locale-identifier" })

  -- Reset selection data
  player_table.selected_inserter = nil
  player_table.selections = {}

  -- Refresh GUIs
  local SelectionGui = util.get_gui(player.index)
  if SelectionGui then
    SelectionGui:destroy()
  end
  selection_gui.build(player, player_table)
end

function player_data.register_for_iteration(player_index, player_table)
  global.players_to_iterate[player_index] = true
  player_table.flags.iterating = true
end

function player_data.deregister_from_iteration(player_index, player_table)
  global.players_to_iterate[player_index] = nil
  player_table.iteration_data = nil

  player_table.flags.iterating = false
end

return player_data
