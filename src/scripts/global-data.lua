local global_data = {}

local table = require("__flib__.table")

local constants = require("constants")

function global_data.init()
  global.players = {}
  global.players_to_iterate = {}
  global.settings = {}

  global_data.build_entity_rates()
  global_data.update_settings()
end

function global_data.build_entity_rates()
  local entity_rates = {
    transport_belts = {},
    train_wagons_per_second = {},
    train_wagons_per_minute = {},
    train_wagons_per_hour = {}
  }

  local get_entities = game.get_filtered_entity_prototypes

  -- transport belts
  for name, prototype in pairs(get_entities(constants.units.materials.transport_belts.entity_filters)) do
    entity_rates.transport_belts[name] = {
      divisor = prototype.belt_speed * 480,
      multiplier = 1,
      types = {item = true}
    }
  end

  -- wagons
  for name, prototype in pairs(get_entities(constants.units.materials.train_wagons_per_minute.entity_filters)) do
    if prototype.type == "cargo-wagon" then
      entity_rates.train_wagons_per_second[name] = {
        divide_by_stack_size = true,
        divisor = prototype.get_inventory_size(defines.inventory.cargo_wagon),
        multiplier = 1,
        types = {item = true}
      }
      entity_rates.train_wagons_per_minute[name] = {
        divide_by_stack_size = true,
        divisor = prototype.get_inventory_size(defines.inventory.cargo_wagon),
        multiplier = 60,
        types = {item = true}
      }
      entity_rates.train_wagons_per_hour[name] = {
        divide_by_stack_size = true,
        divisor = prototype.get_inventory_size(defines.inventory.cargo_wagon),
        multiplier = 60 * 60,
        types = {item = true}
      }
    else
      entity_rates.train_wagons_per_second[name] = {
        divisor = prototype.fluid_capacity,
        multiplier = 1,
        types = {fluid = true}
      }
      entity_rates.train_wagons_per_minute[name] = {
        divisor = prototype.fluid_capacity,
        multiplier = 60,
        types = {fluid = true}
      }
      entity_rates.train_wagons_per_hour[name] = {
        divisor = prototype.fluid_capacity,
        multiplier = 60 * 60,
        types = {fluid = true}
      }
    end
  end

  global.entity_rates = entity_rates
end

function global_data.update_settings()
  local global_settings = global.settings
  local map_settings = settings.global
  global_settings.entities_per_tick = map_settings["rcalc-entities-per-tick"].value
end

return global_data
