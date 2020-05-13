local player_data = {}

function player_data.init(index, player)
  global.players[index] = {
    flags = {
      can_open_gui = false,
      gui_open = false,
      translate_on_join = false
    },
    gui = nil,
    settings = {},
    translations = {}
  }

  player_data.refresh(player, global.players[index])
end

function player_data.import_settings(player, player_table, setup)
  local settings = player_table.settings
  if setup then
    settings.units = "per-minute"
  end
  -- TODO
end

function player_data.refresh(player, player_table, setup)
  -- TODO: close all GUIs

  -- refresh settings
  player_data.import_settings(player, player_table, setup)
end

return player_data