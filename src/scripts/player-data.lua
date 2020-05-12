local player_data = {}

function player_data.init(index, player)
  global.players[index] = {
    dictionary = {},
    flags = {},
    gui = {},
    regions = {},
    settings = {}
  }

  player_data.refresh(player, global.players[index])
end

function player_data.import_settings(player, player_table)
  local settings = {}
  -- TODO

  player_table.settings = settings
end

function player_data.refresh(player, player_table)
  -- TODO: close all GUIs
  -- refresh settings
  player_data.import_settings(player, player_table)
end

return player_data