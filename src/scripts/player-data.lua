local player_data = {}

local selection_gui = require("scripts.gui.selection")

function player_data.init(index)
  global.players[index] = {
    flags = {
      iterating = false
    },
    guis = {},
    last_tool_measure = "all",
    selected_inserter = nil
  }
end

function player_data.refresh(player, player_table)
  -- update active language
  player.request_translation{"locale-identifier"}

  -- remove selected inserter
  player_table.selected_inserter = nil

  -- refresh GUIs
  if player_table.guis.selection then
    selection_gui.destroy(player_table)
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
