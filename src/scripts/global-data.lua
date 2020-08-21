local global_data = {}

local util = require("__core__.lualib.util")

local constants = require("constants")

function global_data.init()
  global.players = {}
  global.players_to_iterate = {}
  global.settings = {}

  global_data.build_unit_data()
  global_data.update_settings()
end

function global_data.build_unit_data()
  local unit_data = {
    [constants.units_lookup.materials_per_second] = {
      divisor = 1,
      multiplier = 1,
      types = {fluid=true, item=true}
    },
    [constants.units_lookup.materials_per_minute] = {
      divisor = 1,
      multiplier = 60,
      types = {fluid=true, item=true}
    },
    [constants.units_lookup.power] = {
      divisor = 1,
      multiplier = 60,
      types = {entity=true}
    }
  }

  local get_entities = game.get_filtered_entity_prototypes
  local transport_belts = {}
  for name, prototype in pairs(get_entities{{filter="type", type="transport-belt"}}) do
    transport_belts[name] = {
      divisor = prototype.belt_speed * 480,
      multiplier = 1,
      types = {item=true}
    }
  end
  unit_data[constants.units_lookup.transport_belts] = transport_belts

  local wagons_per_second = {}
  for name, prototype in pairs(get_entities{{filter="type", type="cargo-wagon"}}) do
    wagons_per_second[name] = {
      divide_by_stack_size = true,
      divisor = prototype.get_inventory_size(defines.inventory.cargo_wagon),
      multiplier = 1,
      types = {item=true},
    }
  end
  for name, prototype in pairs(get_entities{{filter="type", type="fluid-wagon"}}) do
    wagons_per_second[name] = {
      divisor = prototype.fluid_capacity,
      multiplier = 1,
      types = {item=true}
    }
  end
  unit_data[constants.units_lookup.train_wagons_per_second] = wagons_per_second

  local wagons_per_minute = {}
  for name, t in pairs(wagons_per_second) do
    local new_t = table.deepcopy(t)
    new_t.multiplier = 60
    wagons_per_minute[name] = new_t
  end
  unit_data[constants.units_lookup.train_wagons_per_minute] = wagons_per_minute

  global.unit_data = unit_data
end

function global_data.update_settings()
  local global_settings = global.settings
  local map_settings = settings.global
  global_settings.entities_per_tick = map_settings["rcalc-entities-per-tick"].value
end

return global_data