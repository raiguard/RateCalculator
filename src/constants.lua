local constants = {}

constants.energy_source_calculators = {
  burner = {
    prototype_name = "burner_prototype",
    measure = "materials"
  },
  electric = {
    prototype_name = "electric_energy_source_prototype",
    measure = "electricity"
  },
  fluid = {
    prototype_name = "fluid_energy_source_prototype",
    measure = "materials"
  },
  heat = {
    prototype_name = "heat_energy_source_prototype",
    measure = "heat"
  }
}

constants.entity_data = {
  ["accumulator"] = {},
  ["ammo-turret"] = {},
  ["arithmetic-combinator"] = {},
  ["arrow"] = {},
  ["artillery-flare"] = {},
  ["artillery-projectile"] = {},
  ["artillery-turret"] = {},
  ["artillery-wagon"] = {},
  ["assembling-machine"] = {
      blacklist = {
        -- mining drones - https://mods.factorio.com/mod/Mining_Drones
        ["mining-depot"] = true,
        -- transport drones - https://mods.factorio.com/mod/Transport_Drones
        ["buffer-depot"] = true,
        ["fuel-depot"] = true,
        ["request-depot"] = true,
        ["supply-depot"] = true
      },
      calculator = "recipe",
      produces_consumes_items = true
  },
  ["beacon"] = {},
  ["beam"] = {},
  ["boiler"] = {
    calculator = "boiler",
    produces_consumes_items = true
  },
  ["burner-generator"] = {},
  ["car"] = {},
  ["cargo-wagon"] = {},
  ["character"] = {},
  ["character-corpse"] = {},
  ["cliff"] = {},
  ["combat-robot"] = {},
  ["constant-combinator"] = {},
  ["construction-robot"] = {},
  ["container"] = {},
  ["corpse"] = {},
  ["curved-rail"] = {},
  ["decider-combinator"] = {},
  ["deconstructible-tile-proxy"] = {},
  ["electric-energy-interface"] = {},
  ["electric-pole"] = {},
  ["electric-turret"] = {},
  ["entity-ghost"] = {},
  ["explosion"] = {},
  ["fire"] = {},
  ["fish"] = {},
  ["flame-thrower-explosion"] = {},
  ["fluid-turret"] = {},
  ["fluid-wagon"] = {},
  ["flying-text"] = {},
  ["furnace"] = {
    blacklist = {
      -- transport drones - https://mods.factorio.com/mod/Transport_Drones
      ["fluid-depot"] = true
    },
    calculator = "recipe",
    produces_consumes_items = true
  },
  ["gate"] = {},
  ["generator"] = {
    calculator = "generator",
    produces_consumes_items = true
  },
  ["heat-interface"] = {},
  ["heat-pipe"] = {},
  ["highlight-box"] = {},
  ["infinity-container"] = {},
  ["infinity-pipe"] = {},
  ["inserter"] = {},
  ["item-entity"] = {},
  ["item-request-proxy"] = {},
  ["lab"] = {
    calculator = "lab",
    produces_consumes_items = true
  },
  ["lamp"] = {},
  ["land-mine"] = {},
  ["loader"] = {},
  ["loader-1x1"] = {},
  ["locomotive"] = {},
  ["logistic-container"] = {},
  ["logistic-robot"] = {},
  ["market"] = {},
  ["mining-drill"] = {
    calculator = "mining-drill",
    produces_consumes_items = true
  },
  ["offshore-pump"] = {
    calculator = "offshore-pump",
    produces_consumes_items = true
  },
  ["particle-source"] = {},
  ["pipe"] = {},
  ["pipe-to-ground"] = {},
  ["player-port"] = {},
  ["power-switch"] = {},
  ["programmable-speaker"] = {},
  ["projectile"] = {},
  ["pump"] = {},
  ["radar"] = {},
  ["rail-chain-signal"] = {},
  ["rail-remnants"] = {},
  ["rail-signal"] = {},
  ["reactor"] = {
    calculator = "reactor"
  },
  ["resource"] = {},
  ["roboport"] = {},
  ["rocket-silo"] = {
    calculator = "recipe",
    produces_consumes_items = true
  },
  ["rocket-silo-rocket"] = {},
  ["rocket-silo-rocket-shadow"] = {},
  ["simple-entity"] = {},
  ["simple-entity-with-force"] = {},
  ["simple-entity-with-owner"] = {},
  ["smoke-with-trigger"] = {},
  ["solar-panel"] = {},
  ["speech-bubble"] = {},
  ["spider-leg"] = {},
  ["spider-vehicle"] = {},
  ["splitter"] = {},
  ["sticker"] = {},
  ["storage-tank"] = {},
  ["straight-rail"] = {},
  ["stream"] = {},
  ["tile-ghost"] = {},
  ["train-stop"] = {},
  ["transport-belt"] = {},
  ["tree"] = {},
  ["turret"] = {},
  ["underground-belt"] = {},
  ["unit"] = {},
  ["unit-spawner"] = {},
  ["wall"] = {},
}

constants.measures = {
  all = {i = 1, color = {r = 1, g = 1}, label = "All", selection_box = "entity"},
  materials = {i = 2, color = {r = 0.5, g = 1}, label = "Materials", selection_box = "copy"},
  electricity = {i = 3, color = {57, 156, 251}, label = "Electricity", selection_box = "electricity"},
  pollution = {i = 4, color = {r = 1, g = 0.3, b = 0.3}, label = "Pollution", selection_box = "not-allowed"},
  heat = {i = 5, color = {r = 1, g = 0.5, }, label = "Heat", selection_box = "entity"}
}

-- for scrolling
constants.measures_arr = {}
for k in pairs(constants.measures) do
  constants.measures_arr[#constants.measures_arr+1] = k
end

constants.rate_key_overrides = {
  ["entity.ee-infinity-accumulator-primary-output"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-primary-input"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-secondary-output"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-secondary-input"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-tertiary-output"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-tertiary-input"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"}
}

local units = {
  materials_per_second = "rcalc-gui-units.materials-per-second",
  materials_per_minute = "rcalc-gui-units.materials-per-minute",
  transport_belts = "rcalc-gui-units.transport-belts",
  train_wagons_per_second = "rcalc-gui-units.train-wagons-per-second",
  train_wagons_per_minute = "rcalc-gui-units.train-wagons-per-minute",
  power = "rcalc-gui-units.power"
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

constants.widths = {
  en = {50, 75, 49, 84},
  ru = {62, 73, 92, 96}
}

return constants
