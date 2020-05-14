local constants = {}

local selection_tool_types = {
  "assembling-machine",
  "furnace",
  "lab",
  "mining-drill",
  "offshore-pump",
  "rocket-silo"
}

constants.selection_tool_types = selection_tool_types

constants.locale_gui_data = {
  ["en"] = {

  }
}

-- UNITS

local units = {
  materials_per_second = {"rcalc-gui-units.materials-per-second"},
  materials_per_minute = {"rcalc-gui-units.materials-per-minute"},
  transport_belts = {"rcalc-gui-units.transport-belts"},
  inserters = {"rcalc-gui-units.inserters"},
  train_wagons_per_second = {"rcalc-gui-units.train-wagons-per-second"},
  train_wagons_per_minute = {"rcalc-gui-units.train-wagons-per-minute"}
}

local units_dropdown_contents = {}
local units_lookup = {}

local i = 0
for key, value in pairs(units) do
  i = i + 1
  units_dropdown_contents[i] = value
  units_lookup[key] = i
end

constants.units_dropdown_contents = units_dropdown_contents
constants.units_lookup = units_lookup

return constants