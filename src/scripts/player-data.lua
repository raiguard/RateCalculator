local player_data = {}

local constants = require("constants")

local rates_gui = require("scripts.gui.rates")

function player_data.init(index)
  global.players[index] = {
    flags = {
      gui_open = false,
      iterating = false
    },
    guis = {},
    iteration_index = nil,
    settings = {}
  }
end

function player_data.update_settings(player, player_table)
  local settings = player_table.settings
  settings.units = constants.units_lookup.materials_per_minute

  local unit_data = global.unit_data
  settings.transport_belt = next(unit_data[constants.units_lookup.transport_belts])
  settings.wagon = next(unit_data[constants.units_lookup.train_wagons_per_minute])
end

function player_data.refresh(player, player_table)
  -- refresh settings
  player_data.update_settings(player, player_table)
  -- update active language
  player.request_translation{"locale-identifier"}

  -- refresh GUIs
  if player_table.guis.rates then
    rates_gui.destroy(player_table)
  end
  rates_gui.build(player, player_table)
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