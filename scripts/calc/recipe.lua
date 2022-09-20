local calc_util = require("__RateCalculator__.scripts.calc.util")

--- Calculates how long it takes to launch the rocket.
---
--- These stages mirror the in-game progression and timing exactly. Most steps take an additional tick (+1)
--- due to how the game code is written. If one stage is completed, you can only progress to the next one
--- in the next tick. No stages can be skipped, meaning a minimal sequence time is around 10 ticks long.
---
--- Source: https://github.com/ClaudeMetz/FactoryPlanner/blob/0f0aeae03386f78290d932cf51130bbcb2afa83d/modfiles/data/handlers/generator_util.lua#L364
---
--- @param prototype LuaEntityPrototype
--- @return number?
local function get_seconds_per_launch(prototype)
  local rocket_prototype = prototype.rocket_entity_prototype
  if not rocket_prototype then
    return nil
  end

  local rocket_flight_threshold = 0.5 -- hardcoded in the game files
  local launch_steps = {
    lights_blinking_open = (1 / prototype.light_blinking_speed) + 1,
    doors_opening = (1 / prototype.door_opening_speed) + 1,
    doors_opened = prototype.rocket_rising_delay + 1,
    rocket_rising = (1 / rocket_prototype.rising_speed) + 1,
    rocket_ready = 14, -- estimate for satellite insertion delay
    launch_started = prototype.launch_wait_time + 1,
    engine_starting = (1 / rocket_prototype.engine_starting_speed) + 1,
    -- This calculates a fractional amount of ticks. Also, math.log(x) calculates the natural logarithm
    rocket_flying = math.log(
      1 + rocket_flight_threshold * rocket_prototype.flying_acceleration / rocket_prototype.flying_speed
    ) / math.log(1 + rocket_prototype.flying_acceleration),
    lights_blinking_close = (1 / prototype.light_blinking_speed) + 1,
    doors_closing = (1 / prototype.door_opening_speed) + 1,
  }

  local total_ticks = 0
  for _, ticks_taken in pairs(launch_steps) do
    total_ticks = total_ticks + ticks_taken
  end

  return (total_ticks / 60) -- retured value is in seconds
end

--- @param rates table
--- @param entity LuaEntity
--- @param emissions_per_second number
--- @param prototypes table<string, table<string, LuaEntityPrototype>>
return function(rates, entity, emissions_per_second, prototypes)
  --- @type LuaRecipe
  local recipe = entity.get_recipe() or (entity.type == "furnace" and entity.previous_recipe)

  if recipe then
    -- The game engine has a hard limit of one craft per tick, so the maximum possible crafts per second is 60
    local crafts_per_second = math.min(entity.crafting_speed / recipe.energy, 60)

    local productivity = (entity.productivity_bonus + 1)

    -- Calculate and apply the ratio of rocket craft time to launch time
    if entity.type == "rocket-silo" then
      local prototype = entity.prototype
      local seconds_per_launch = get_seconds_per_launch(prototype)
      local normal_crafts = prototype.rocket_parts_required
      local missed_crafts = seconds_per_launch * crafts_per_second * productivity
      local ratio = normal_crafts / (normal_crafts + missed_crafts)
      crafts_per_second = crafts_per_second * ratio
    end

    for _, ingredient in ipairs(recipe.ingredients) do
      local amount = ingredient.amount * crafts_per_second
      local ingredient_type = ingredient.type
      local ingredient_name = ingredient.name
      local ingredient_localised_name = prototypes[ingredient_type][ingredient_name].localised_name
      calc_util.add_rate(
        rates.materials,
        "input",
        ingredient_type,
        ingredient_name,
        ingredient_localised_name,
        amount,
        "recipe" .. "/" .. recipe.name
      )
    end

    for _, product in ipairs(recipe.products) do
      local adjusted_crafts_per_second = crafts_per_second * (product.probability or 1)

      -- Take the average amount if there is a min and max
      local amount = product.amount or (product.amount_max - ((product.amount_max - product.amount_min) / 2))
      local catalyst_amount = product.catalyst_amount or 0

      -- Catalysts are not affected by productivity
      local amount = (catalyst_amount + ((amount - catalyst_amount) * productivity)) * adjusted_crafts_per_second

      -- Display different temperatures as different outputs
      local product_name = product.name .. (product.temperature and "." .. product.temperature or "")
      local product_localised_name = prototypes[product.type][product.name].localised_name
      if product.temperature then
        product_localised_name = {
          "",
          product_localised_name,
          " (",
          { "format-degrees-c-compact", product.temperature },
          ")",
        }
      end

      calc_util.add_rate(
        rates.materials,
        "output",
        product.type,
        product_name,
        product_localised_name,
        amount,
        "recipe" .. "/" .. recipe.name,
        product.temperature
      )
    end

    return emissions_per_second * recipe.prototype.emissions_multiplier * (1 + entity.pollution_bonus)
  end

  return emissions_per_second
end
