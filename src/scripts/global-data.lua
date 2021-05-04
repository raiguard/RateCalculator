local global_data = {}

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
    per_second = {},
    per_minute = {},
    per_hour = {},
    transport_belts = {}
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

  -- containers
  for name, prototype in pairs(get_entities(constants.unit_container_filters)) do
    if prototype.type == "fluid-wagon" or prototype.type == "storage-tank" then
      entity_rates.per_second[name] = {
        divisor = prototype.fluid_capacity,
        multiplier = 1,
        types = {fluid = true}
      }
      entity_rates.per_minute[name] = {
        divisor = prototype.fluid_capacity,
        multiplier = 60,
        types = {fluid = true}
      }
      entity_rates.per_hour[name] = {
        divisor = prototype.fluid_capacity,
        multiplier = 60 * 60,
        types = {fluid = true}
      }
    else
      local inventory_def = prototype.type == "cargo-wagon" and "cargo_wagon" or "chest"
      local inventory_size = prototype.get_inventory_size(defines.inventory[inventory_def])
      entity_rates.per_second[name] = {
        divide_by_stack_size = true,
        divisor = inventory_size,
        multiplier = 1,
        types = {item = true}
      }
      entity_rates.per_minute[name] = {
        divide_by_stack_size = true,
        divisor = inventory_size,
        multiplier = 60,
        types = {item = true}
      }
      entity_rates.per_hour[name] = {
        divide_by_stack_size = true,
        divisor = inventory_size,
        multiplier = 60 * 60,
        types = {item = true}
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
