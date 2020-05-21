local constants = {}

-- LOCALE POSITIONING

constants.locale_gui_data = {
  ["en"] = {

  }
}

-- SELECTION TOOL

-- type -> name blacklist
constants.selection_tool_filters = {
  ["assembling-machine"] = {
    -- mining drones
    ["mining-depot"] = true,
    -- transport drones
    ["buffer-depot"] = true,
    ["fuel-depot"] = true,
    ["request-depot"] = true,
    ["supply-depot"] = true
  },
  ["furnace"] = {
    ["fluid-depot"] = true
  },
  ["lab"] = {},
  ["mining-drill"] = {},
  ["offshore-pump"] = {},
  ["rocket-silo"] = {},
}

-- UNITS

local units = {
  materials_per_second = {"rcalc-gui-units.materials-per-second"},
  materials_per_minute = {"rcalc-gui-units.materials-per-minute"},
  transport_belts = {"rcalc-gui-units.transport-belts"},
  train_wagons_per_second = {"rcalc-gui-units.train-wagons-per-second"},
  train_wagons_per_minute = {"rcalc-gui-units.train-wagons-per-minute"}
}

local units_dropdown_localised = {}
local units_lookup = {}

local i = 0
for key, value in pairs(units) do
  i = i + 1
  units_dropdown_localised[i] = value
  units_lookup[key] = i
end

constants.units_dropdown_contents = units_dropdown_localised
constants.units_lookup = units_lookup

constants.units_to_setting_name = {
  [units_lookup.transport_belts] = "transport_belt",
  [units_lookup.train_wagons_per_second] = "wagon",
  [units_lookup.train_wagons_per_minute] = "wagon"
}

-- CHOOSE ELEM BUTTONS

-- TODO use filters
constants.choose_elem_buttons = {
  [units_lookup.transport_belts] = {
    type = "transport_belt",
    filters = {{filter="type", type="transport-belt"}}
  },
  [units_lookup.train_wagons_per_second] = {
    type = "wagon",
    filters = {{filter="type", type="cargo-wagon"}, {filter="type", type="fluid-wagon"}}
  },
  [units_lookup.train_wagons_per_minute] = {
    type = "wagon",
    filters = {{filter="type", type="cargo-wagon"}, {filter="type", type="fluid-wagon"}}
  }
}

return constants