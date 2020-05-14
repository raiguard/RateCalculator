local global_data = {}

local constants = require("constants")

function global_data.init()
  global.players = {}

  global_data.build_unit_info()
end

function global_data.build_unit_info()
  local unit_info = {
    [constants.units_lookup.materials_per_second] = {
      divisor = 1,
      multiplier = 1
    },
    [constants.units_lookup.materials_per_minute] = {
      divisor = 1,
      multiplier = 60
    },
  }

  local get_entities = game.get_filtered_entity_prototypes
  local transport_belts = {}
  for name, prototype in pairs(get_entities{{filter="type", type="transport-belt"}}) do
    transport_belts[name] = {
      divisor = prototype.belt_speed * 480,
      multiplier = 1
    }
  end
  unit_info[constants.units_lookup.transport_belts] = transport_belts

  local wagons_per_second = {}
  for name, prototype in pairs(get_entities{{filter="type", type="cargo-wagon"}}) do
    wagons_per_second[name] = {
      divisor = prototype.get_inventory_size(defines.inventory.cargo_wagon),
      material_type = "item",
      multiplier = 1
    }
  end
  for name, prototype in pairs(get_entities{{filter="type", type="fluid-wagon"}}) do
    wagons_per_second[name] = {
      divisor = prototype.fluid_capacity,
      material_type = "fluid",
      multiplier = 1
    }
  end
  unit_info[constants.units_lookup.train_wagons_per_second] = wagons_per_second

  local wagons_per_minute = {}
  for name, t in pairs(wagons_per_second) do
    wagons_per_minute[name] = {
      divisor = t.divisor,
      material_type = t.material_type,
      multiplier = 60
    }
  end
  unit_info[constants.units_lookup.train_wagons_per_minute] = wagons_per_minute

  global.unit_info = unit_info
end

return global_data