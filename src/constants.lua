local constants = {}

local crafter_types = {
  "assembling-machine",
  "furnace",
  -- "rocket-silo",
}

local crafter_type_lookup = {}

for i = 1, #crafter_types do
  crafter_type_lookup[crafter_types[i]] = true
end

constants.crafter_types = crafter_types
constants.crafter_type_lookup = crafter_type_lookup

constants.locale_gui_data = {
  ["en"] = {

  }
}

constants.units_list = {
  {"rcalc-gui-units.materials-per-second"},
  {"rcalc-gui-units.materials-per-minute"},
  {"rcalc-gui-units.transport-belts"},
  {"rcalc-gui-units.inserters"},
  {"rcalc-gui-units.train-wagons-per-second"},
  {"rcalc-gui-units.train-wagons-per-minute"}
}

return constants