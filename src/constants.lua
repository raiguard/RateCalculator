local constants = {}

-- SELECTION TOOL

constants.alt_selection_color = {57, 156, 251}

constants.selection_color = {r = 1, g = 1}

-- type -> name blacklist
-- categories with __is_production_machine will not check energy_source type
constants.selection_tool_filters = {
  ["accumulator"] = {},
  ["arithmetic-combinator"] = {},
  ["assembling-machine"] = {
    __is_production_machine = true,
    -- mining drones - https://mods.factorio.com/mod/Mining_Drones
    ["mining-depot"] = true,
    -- transport drones - https://mods.factorio.com/mod/Transport_Drones
    ["buffer-depot"] = true,
    ["fuel-depot"] = true,
    ["request-depot"] = true,
    ["supply-depot"] = true
  },
  ["beacon"] = {},
  ["boiler"] = {
    __is_production_machine = true
  },
  -- cannot read power production of these yet, so don't include them
  -- ["burner-generator"] = {},
  ["car"] = {},
  ["decider-combinator"] = {},
  ["electric-energy-interface"] = {},
  ["electric-turret"] = {},
  ["furnace"] = {
    __is_production_machine = true,
    -- transport drones - https://mods.factorio.com/mod/Transport_Drones
    ["fluid-depot"] = true
  },
  ["generator"] = {
    __is_production_machine = true
  },
  ["inserter"] = {},
  ["lab"] = {
    __is_production_machine = true
  },
  ["lamp"] = {},
  ["locomotive"] = {},
  ["mining-drill"] = {
    __is_production_machine = true
  },
  ["offshore-pump"] = {
    __is_production_machine = true
  },
  ["programmable-speaker"] = {},
  ["pump"] = {},
  ["radar"] = {},
  ["reactor"] = {},
  ["roboport"] = {},
  ["solar-panel"] = {},
  ["rocket-silo"] = {
    __is_production_machine = true
  }
}

-- UNITS

local units = {
  materials_per_second = {"rcalc-gui-units.materials-per-second"},
  materials_per_minute = {"rcalc-gui-units.materials-per-minute"},
  transport_belts = {"rcalc-gui-units.transport-belts"},
  train_wagons_per_second = {"rcalc-gui-units.train-wagons-per-second"},
  train_wagons_per_minute = {"rcalc-gui-units.train-wagons-per-minute"},
  power = {"rcalc-gui-units.power"}
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

constants.choose_elem_buttons = {
  [units_lookup.transport_belts] = {
    type = "transport_belt",
    filters = {{filter = "type", type = "transport-belt"}}
  },
  [units_lookup.train_wagons_per_second] = {
    type = "wagon",
    filters = {{filter = "type", type = "cargo-wagon"}, {filter = "type", type = "fluid-wagon"}}
  },
  [units_lookup.train_wagons_per_minute] = {
    type = "wagon",
    filters = {{filter = "type", type = "cargo-wagon"}, {filter = "type", type = "fluid-wagon"}}
  }
}

-- RATES

constants.rate_key_overrides = {
  ["entity.ee-infinity-accumulator-primary-output"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-primary-input"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-secondary-output"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-secondary-input"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-tertiary-output"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-tertiary-input"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"}
}

-- GUI

constants.widths = {
  en = {50, 75, 49, 84},
  ru = {62, 73, 92, 96}
}

return constants