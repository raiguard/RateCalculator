local constants = {}

-- SELECTION TOOL

constants.entity_type_data = {
  ["accumulator"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
  ["arithmetic-combinator"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
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
    calculators = {
      electricity = {"generic"},
      materials = {"recipe"}
    }
  },
  ["beacon"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
  ["boiler"] = {
    calculators = {
      electricity = {"generic"},
      materials = {"boiler"}
    }
  },
  -- cannot read power production of these yet, so don't include them
  -- ["burner-generator"] = {},
  ["car"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
  ["decider-combinator"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
  ["electric-energy-interface"] = {
    calculators = {
      electricity = {"electric-energy-interface"}
    }
  },
  ["electric-turret"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
  ["furnace"] = {
    blacklist = {
      -- transport drones - https://mods.factorio.com/mod/Transport_Drones
      ["fluid-depot"] = true
    },
    calculators = {
      electricity = {"generic"},
      materials = {"recipe"}
    }
  },
  ["generator"] = {
    calculators = {
      electricity = {"generic"},
      materials = {"generator"}
    }
  },
  ["inserter"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
  ["lab"] = {
    calculators = {
      electricity = {"generic"},
      materials = {"lab"}
    }
  },
  ["lamp"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
  -- ["locomotive"] = {
  --   calculators = {
  --     electricity = {"generic"}
  --   }
  -- },
  ["mining-drill"] = {
    calculators = {
      electricity = {"generic"},
      materials = {"mining-drill"}
    }
  },
  ["offshore-pump"] = {
    calculators = {
      materials = {"mining-drill"}
    }
  },
  ["programmable-speaker"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
  ["pump"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
  ["radar"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
  ["reactor"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
  ["roboport"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
  ["solar-panel"] = {
    calculators = {
      electricity = {"generic"}
    }
  },
  ["rocket-silo"] = {
    calculators = {
      electricity = {"generic"},
      materials = {"recipe"}
    }
  }
}

constants.selection_tools = {
  all = {i = 1, color = {r = 1, g = 1}, label = "All", selection_box = "entity"},
  materials = {i = 2, color = {r = 0.5, g = 1}, label = "Materials", selection_box = "copy"},
  electricity = {i = 3, color = {57, 156, 251}, label = "Electricity", selection_box = "electricity"},
  -- pollution = {i = 4, color = {r = 1, g = 0.3, b = 0.3}, label = "Pollution", selection_box = "not-allowed"},
  -- heat = {i = 5, color = {r = 1, g = 0.5, }, label = "Heat", selection_box = "entity"}
}

-- for scrolling
constants.selection_tool_measures = {}
for k in pairs(constants.selection_tools) do
  constants.selection_tool_measures[#constants.selection_tool_measures+1] = k
end

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
