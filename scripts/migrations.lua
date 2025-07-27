local flib_migration = require("__flib__.migration")

local calc = require("scripts.calc")
local main_gui = require("scripts.gui.main")

local by_version = {
  ["3.0.0"] = function()
    for _, player in pairs(game.players) do
      for _, child in pairs(player.gui.screen.children) do
        if child.get_mod() == "RateCalculator" then
          child.destroy()
        end
      end
    end
    storage = { gui = {} }
  end,
  ["4.0.0"] = function()
    for _, player in pairs(game.players) do
      for _, child in pairs(player.gui.screen.children) do
        if child.get_mod() == "RateCalculator" then
          child.destroy()
        end
      end
    end
    storage = {}
    calc.on_init()
    main_gui.on_init()
  end,
}

--- @param e ConfigurationChangedData
local function on_configuration_changed(e)
  flib_migration.on_config_changed(e, by_version)
end

local migrations = {}

migrations.on_configuration_changed = on_configuration_changed

return migrations
