local flib_migration = require("__flib__/migration")

local calc = require("__RateCalculator__/scripts/calc")
local gui = require("__RateCalculator__/scripts/gui")

local by_version = {
  ["3.0.0"] = function()
    -- NUKE EVERYTHING
    global = {}
    -- Re-init
    calc.on_init()
    gui.on_init()
  end,
}

--- @param e ConfigurationChangedData
local function on_configuration_changed(e)
  flib_migration.on_config_changed(e, by_version)
end

local migrations = {}

migrations.on_configuration_changed = on_configuration_changed

return migrations
