-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- depencencies
local event = require('__RaiLuaLib__.lualib.event')
local migration = require('__RaiLuaLib__.lualib.migration')

-- locals
local string_gsub = string.gsub
local string_sub = string.sub

local crafter_types = {['assembling-machine'] = true, ['furnace'] = true, ['rocket-silo'] = true}

-- classes
local Zone = require('scripts.classes.zone')

-- -----------------------------------------------------------------------------
-- PLAYER DATA

local function setup_player(index, player)
  global.players[index] = {
    dictionary = {},
    flags = {},
    gui = {},
    regions = {},
    settings = {}
  }
end

local function import_player_settings(player, player_table)
  local settings = {}
  for name,t in pairs(player.mod_settings) do
    if string_sub(name, 1, 5) == 'rcalc-' then
      settings[string_gsub(string_gsub(name, 'rcalc%-', ''), '%-', '_')] = t.value
    end
  end
  player_table.settings = settings
end

local function refresh_player_data(player, player_table)
  -- TODO: close all GUIs
  -- refresh settings
  import_player_settings(player, player_table)
end

-- -----------------------------------------------------------------------------
-- STATIC HANDLERS

event.on_init(function()
  global.players = {}
  for i,p in pairs(game.players) do
    setup_player(i)
    refresh_player_data(p, global.players[i])
  end
end)

event.on_player_created(function(e)
  setup_player(e.player_index, game.get_player(e.player_index))
end)

-- PROTOTYPING

event.on_player_selected_area(function(e)
  local player = game.get_player(e.player_index)
  if #e.entities > 0 then
    Zone.new(e.area, e.entities, player, player.surface)
  end
end)

event.on_player_alt_selected_area(function(e)

end)

-- -----------------------------------------------------------------------------
-- MIGRATIONS

local migrations = {}

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    -- refresh player data
    for i,p in pairs(game.players) do
      refresh_player_data(p, global.players[i])
    end
  end
end)