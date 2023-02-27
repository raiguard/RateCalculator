local table = require("__flib__/table")

local calc_util = require("__RateCalculator__/scripts/calc-util")

local gui = require("__RateCalculator__/scripts/gui")

--- @class RatesSet
--- @field type string
--- @field name string
--- @field output double
--- @field input double
--- @field entities uint

--- @alias CalculationSet table<string, RatesSet>

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
local function process_entity(set, entity, invert)
  local recipe = entity.get_recipe()
  if not recipe and entity.type == "furnace" then
    recipe = entity.previous_recipe
  end
  if not recipe then
    return
  end

  -- The game engine has a hard limit of one craft per tick, or 60 crafts per second
  local crafts_per_second = math.min(entity.crafting_speed / recipe.energy, 60)
  -- Rocket silos will lose time to the launch animation
  if entity.type == "rocket-silo" then
    crafts_per_second = calc_util.get_rocket_adjusted_crafts_per_second(entity, crafts_per_second)
  end

  for _, ingredient in pairs(recipe.ingredients) do
    local amount = ingredient.amount * crafts_per_second
    calc_util.add_rate(set, ingredient.type, ingredient.name, "input", amount, invert)
  end

  local productivity = entity.productivity_bonus + 1

  for _, product in pairs(recipe.products) do
    local adjusted_crafts_per_second = crafts_per_second * (product.probability or 1)

    -- Take the average amount if there is a min and max
    local amount = product.amount or (product.amount_max - ((product.amount_max - product.amount_min) / 2))
    local catalyst_amount = product.catalyst_amount or 0

    -- Catalysts are not affected by productivity
    local amount = (catalyst_amount + ((amount - catalyst_amount) * productivity)) * adjusted_crafts_per_second

    calc_util.add_rate(set, product.type, product.name, "output", amount, invert)
  end
end

--- @param set CalculationSet
--- @param entities LuaEntity[]
--- @param invert boolean
local function process_entities(set, entities, invert)
  for _, entity in pairs(entities) do
    process_entity(set, entity, invert)
  end
end

--- @param e EventData.on_player_selected_area
local function on_player_selected_area(e)
  if e.item ~= "rcalc-selection-tool" then
    return
  end
  if not next(e.entities) then
    return
  end
  local player_sets = table.get_or_insert(global.calculation_sets, e.player_index, {})
  --- @type CalculationSet
  local new_set = {}
  table.insert(player_sets, new_set)
  process_entities(new_set, e.entities, false)

  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  gui.show(player, new_set)
end

--- @param e EventData.on_player_alt_selected_area
local function on_player_alt_selected_area(e)
  if e.item ~= "rcalc-selection-tool" then
    return
  end
  if not next(e.entities) then
    return
  end
  local player_sets = table.get_or_insert(global.calculation_sets, e.player_index, {})
  if not next(player_sets) then
    table.insert(player_sets, {})
  end
  local set = player_sets[#player_sets]
  process_entities(set, e.entities, false)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  gui.show(player, set)
end

--- @param e EventData.on_player_reverse_selected_area
local function on_player_reverse_selected_area(e)
  if e.item ~= "rcalc-selection-tool" then
    return
  end
  if not next(e.entities) then
    return
  end
  local player_sets = table.get_or_insert(global.calculation_sets, e.player_index, {})
  if not next(player_sets) then
    table.insert(player_sets, {})
  end
  local set = player_sets[#player_sets]
  process_entities(set, e.entities, true)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  gui.show(player, set)
end

local function on_init()
  --- @type table<uint, CalculationSet[]>
  global.calculation_sets = {}
end

local tool = {}

tool.on_init = on_init

tool.events = {
  [defines.events.on_player_selected_area] = on_player_selected_area,
  [defines.events.on_player_alt_selected_area] = on_player_alt_selected_area,
  [defines.events.on_player_reverse_selected_area] = on_player_reverse_selected_area,
}

return tool
