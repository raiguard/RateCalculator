local constants = {}

constants.colors = {
  input = {r = 1, g = 0.6, b = 0.6},
  output = {r = 0.6, g = 1, b = 0.6},
  white = {r = 1, g = 1, b = 1}
}

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
  -- ["arrow"] = {},
  -- ["artillery-flare"] = {},
  -- ["artillery-projectile"] = {},
  ["artillery-turret"] = {},
  -- ["artillery-wagon"] = {},
  ["assembling-machine"] = {
      name_blacklist = {
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
  -- ["beam"] = {},
  ["boiler"] = {
    calculator = "boiler",
    produces_consumes_items = true
  },
  -- TODO: burner generators are not yet supported!
  ["burner-generator"] = {},
  -- ["car"] = {},
  -- ["cargo-wagon"] = {},
  -- ["character"] = {},
  -- ["character-corpse"] = {},
  -- ["cliff"] = {},
  -- ["combat-robot"] = {},
  ["constant-combinator"] = {},
  -- ["construction-robot"] = {},
  ["container"] = {},
  -- ["corpse"] = {},
  -- ["curved-rail"] = {},
  ["decider-combinator"] = {},
  -- ["deconstructible-tile-proxy"] = {},
  ["electric-energy-interface"] = {
    match_blacklist = {
      "factory%-power%-input",
      "factory%-power%-output"
    }
  },
  ["electric-pole"] = {},
  ["electric-turret"] = {},
  -- ["entity-ghost"] = {},
  -- ["explosion"] = {},
  -- ["fire"] = {},
  -- ["fish"] = {},
  -- ["flame-thrower-explosion"] = {},
  ["fluid-turret"] = {},
  -- ["fluid-wagon"] = {},
  -- ["flying-text"] = {},
  ["furnace"] = {
    match_blacklist = {
      "transport%-belt%-beltbox"
    },
    name_blacklist = {
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
  -- ["highlight-box"] = {},
  ["infinity-container"] = {},
  ["infinity-pipe"] = {},
  ["inserter"] = {},
  -- ["item-entity"] = {},
  -- ["item-request-proxy"] = {},
  ["lab"] = {
    calculator = "lab",
    produces_consumes_items = true
  },
  ["lamp"] = {
    match_blacklist = {
      "factory%-ceiling%-light"
    }
  },
  -- ["land-mine"] = {},
  ["loader"] = {},
  ["loader-1x1"] = {},
  -- ["locomotive"] = {},
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
  -- ["particle-source"] = {},
  ["pipe"] = {},
  ["pipe-to-ground"] = {},
  ["player-port"] = {},
  ["power-switch"] = {},
  ["programmable-speaker"] = {},
  -- ["projectile"] = {},
  ["pump"] = {},
  ["radar"] = {},
  ["rail-chain-signal"] = {},
  -- ["rail-remnants"] = {},
  ["rail-signal"] = {},
  ["reactor"] = {
    calculator = "reactor"
  },
  -- ["resource"] = {},
  ["roboport"] = {},
  ["rocket-silo"] = {
    calculator = "recipe",
    produces_consumes_items = true
  },
  -- ["rocket-silo-rocket"] = {},
  -- ["rocket-silo-rocket-shadow"] = {},
  ["simple-entity"] = {},
  ["simple-entity-with-force"] = {},
  ["simple-entity-with-owner"] = {},
  -- ["smoke-with-trigger"] = {},
  ["solar-panel"] = {},
  -- ["speech-bubble"] = {},
  -- ["spider-leg"] = {},
  -- ["spider-vehicle"] = {},
  ["splitter"] = {},
  -- ["sticker"] = {},
  ["storage-tank"] = {},
  ["straight-rail"] = {},
  -- ["stream"] = {},
  -- ["tile-ghost"] = {},
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
  materials = {
    index = 1,
    color = {r = 0.5, g = 1},
    alt_color = {r = 0.75, g = 1, b = 0.15},
    label = "Materials",
    selection_box = "copy"
  },
  electricity = {
    index = 2,
    color = {r = 0.225, g = 0.612, b = 0.984},
    alt_color = {r = 0.475, g = 0.862, b = 1},
    label = "Electricity",
    selection_box = "electricity"
  },
  pollution = {
    index = 3,
    color = {r = 1, g = 0.3, b = 0.3},
    alt_color = {r = 1, g = 0.55, b = 0.55},
    label = "Pollution",
    selection_box = "not-allowed"
  },
  heat = {
    index = 4,
    color = {r = 1, g = 0.5, },
    label = "Heat",
    selection_box = "entity"
  },
  all = {
    index = 5,
    color = {r = 1, g = 1},
    label = "All",
    selection_box = "entity"
  }
}

-- for scrolling
constants.measures_arr = {}
for measure in pairs(constants.measures) do
  constants.measures_arr[#constants.measures_arr+1] = measure
end

-- dropdown - does not include "all"
constants.measures_dropdown = {}
for measure in pairs(constants.measures) do
  if measure ~= "all" then
    constants.measures_dropdown[#constants.measures_dropdown+1] = {"gui.rcalc-"..measure}
  end
end

constants.rate_key_overrides = {
  ["entity.ee-infinity-accumulator-primary-output"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-primary-input"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-secondary-output"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-secondary-input"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-tertiary-output"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"},
  ["entity.ee-infinity-accumulator-tertiary-input"] = {"entity", "ee-infinity-accumulator-tertiary-buffer"}
}

constants.row_height = 45

constants.unit_container_filters = {
  {filter = "type", type = "cargo-wagon"},
  {filter = "item-to-place", mode = "and"},
  {filter = "hidden", invert = true, mode = "and"},
  {filter = "type", type = "container"},
  {filter = "item-to-place", mode = "and"},
  {filter = "hidden", invert = true, mode = "and"},
  {filter = "type", type = "fluid-wagon"},
  {filter = "item-to-place", mode = "and"},
  {filter = "hidden", invert = true, mode = "and"},
  {filter = "type", type = "infinity-container"},
  {filter = "item-to-place", mode = "and"},
  {filter = "hidden", invert = true, mode = "and"},
  {filter = "name", name = "infinity-chest", invert = true, mode = "and"},
  {filter = "type", type = "logistic-container"},
  {filter = "item-to-place", mode = "and"},
  {filter = "hidden", invert = true, mode = "and"},
  {filter = "type", type = "storage-tank"},
  {filter = "item-to-place", mode = "and"},
  {filter = "hidden", invert = true, mode = "and"},
}

constants.units = {
  materials = {
    per_second = {
      default_units = {
        divisor = 1,
        multiplier = 1
      },
      button_group = "containers",
      entity_filters = constants.unit_container_filters,
      index = 1,
      localised_name = {"gui.rcalc-per-second"}
    },
    per_minute = {
      default_units = {
        divisor = 1,
        multiplier = 60
      },
      button_group = "containers",
      entity_filters = constants.unit_container_filters,
      default = true,
      index = 2,
      localised_name = {"gui.rcalc-per-minute"}
    },
    per_hour = {
      default_units = {
        divisor = 1,
        multiplier = 60 * 60
      },
      button_group = "containers",
      entity_filters = constants.unit_container_filters,
      index = 3,
      localised_name = {"gui.rcalc-per-hour"}
    },
    transport_belts = {
      entity_filters = {{filter = "type", type = "transport-belt"}},
      index = 4,
      localised_name = {"gui.rcalc-transport-belts"}
    },
    inserters = {
      selection_tool = "rcalc-inserter-selector",
      index = 5,
      localised_name = {"gui.rcalc-inserters"}
    }
  },
  electricity = {
    watts = {
      default = true,
      default_units = {
        divisor = 1,
        multiplier = 60
      },
      index = 1,
      localised_name = {"gui.rcalc-watts"},
      show_totals = true
    }
  },
  pollution = {
    per_second = {
      default_units = {
        divisor = 1,
        multiplier = 1
      },
      index = 1,
      localised_name = {"gui.rcalc-per-second"},
      show_totals = true
    },
    per_minute = {
      default_units = {
        divisor = 1,
        multiplier = 60
      },
      default = true,
      index = 2,
      localised_name = {"gui.rcalc-per-minute"},
      show_totals = true
    },
    per_hour = {
      default_units = {
        divisor = 1,
        multiplier = 60 * 60
      },
      index = 3,
      localised_name = {"gui.rcalc-per-hour",
      show_totals = true
    }}
  },
  heat = {
    watts = {
      default = true,
      default_units = {
        divisor = 1,
        multiplier = 60
      },
      index = 1,
      localised_name = {"gui.rcalc-watts"},
      show_totals = true
    }
  }
}

constants.units_arrs = {}
for measure, units in pairs(constants.units) do
  local items = {}
  for rate_name, data in pairs(units) do
    items[data.index] = rate_name
  end
  constants.units_arrs[measure] = items
end

constants.units_dropdowns = {}
for measure, units in pairs(constants.units) do
  local items = {}
  for _, data in pairs(units) do
    items[#items+1] = data.localised_name
  end
  constants.units_dropdowns[measure] = items
end

constants.widths = {
  en = {60, 60, 75, 60, 84},
  ru = {62, 60, 73, 92, 96}
}

return constants
