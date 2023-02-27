local table = require("__flib__/table")

local calc_util = require("__RateCalculator__/scripts/calc-util")

local gui = require("__RateCalculator__/scripts/gui")

--- @class RatesSet
--- @field type string
--- @field name string
--- @field output double
--- @field input double
--- @field output_machines uint
--- @field input_machines uint

--- @alias CalculationSet table<string, RatesSet>

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
local function process_entity(set, entity, invert)
  local type = entity.type
  if type == "mining-drill" then
    calc_util.process_mining_drill(set, entity, invert)
  else
    calc_util.process_crafter(set, entity, invert)
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
  local profiler = game.create_profiler()
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
  profiler.stop()
  game.print(profiler)
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
local function on_player_alt_reverse_selected_area(e)
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

local calc = {}

calc.on_init = on_init

calc.events = {
  [defines.events.on_player_selected_area] = on_player_selected_area,
  [defines.events.on_player_alt_selected_area] = on_player_alt_selected_area,
  [defines.events.on_player_alt_reverse_selected_area] = on_player_alt_reverse_selected_area,
}

return calc
