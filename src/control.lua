-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- depencencies
local event = require('__RaiLuaLib__.lualib.event')
local gui = require('__RaiLuaLib__.lualib.gui')
local migration = require('__RaiLuaLib__.lualib.migration')

-- -----------------------------------------------------------------------------
-- SETUP AND INTIALIZATION

local function setup_player(index, player)
  global.players[index] = {
    dictionary = {},
    flags = {},
    gui = {}
  }

end

event.on_init(function()
  global.players = {}
  for i,p in pairs(game.players) do
    setup_player(i)
  end
end)

event.on_configuration_changed(function(e)
  migration.on_config_changed(e, {})
end)

event.on_player_created(function(e)
  setup_player(e.player_index, game.get_player(e.player_index))
end)