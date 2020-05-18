local player_data = {}

local constants = require("constants")

function player_data.init(index, player)
  global.players[index] = {
    flags = {
      gui_open = false
    },
    gui = nil,
    settings = {}
  }

  player_data.refresh(player, global.players[index])
end

function player_data.import_settings(player, player_table)
  local settings = player_table.settings
  settings.units = constants.units_lookup.materials_per_minute
  local unit_data = global.unit_data
  settings.transport_belt = next(unit_data[constants.units_lookup.transport_belts])
  settings.wagon = next(unit_data[constants.units_lookup.train_wagons_per_minute])
end

function player_data.refresh(player, player_table)
  -- TODO: close all GUIs

  -- refresh settings
  player_data.import_settings(player, player_table)
end

return player_data