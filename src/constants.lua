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

constants.units_list = {
  {"rcalc-gui-units.materials-per-second"},
  {"rcalc-gui-units.materials-per-minute"},
  {"rcalc-gui-units.transport-belts"},
  {"rcalc-gui-units.inserters"},
  {"rcalc-gui-units.train-wagons-per-second"},
  {"rcalc-gui-units.train-wagons-per-minute"}
}

return constants