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

--- @alias Rates table<string, RatesSet>
--- @alias MeasureRates table<MeasureSource, Rates>

--- @class CalculationSet
--- @field manual_multiplier double
--- @field selected_measure Measure
--- @field rates MeasureRates

--- @return CalculationSet
local function new_calculation_set()
  return {
    manual_multiplier = 1,
    rates = {},
    selected_measure = "per-minute",
  }
end

--- @param rates MeasureRates
--- @param entity LuaEntity
--- @param invert boolean
local function process_entity(rates, entity, invert)
  local type = entity.type
  if type == "mining-drill" then
    calc_util.process_mining_drill(rates, entity, invert)
  elseif type == "assembling-machine" or type == "furnace" or type == "rocket-silo" then
    calc_util.process_crafter(rates, entity, invert)
  elseif type == "reactor" then
    calc_util.process_reactor(rates, entity, invert)
  elseif type == "generator" then
    calc_util.process_generator(rates, entity, invert)
  end

  if type == "burner-generator" or type == "generator" then
    calc_util.add_rate(rates, "power", "entity", entity.name, "output", entity.prototype.max_power_output * 60, invert)
  elseif entity.prototype.electric_energy_source_prototype then
    calc_util.process_electric_energy_source(rates, entity, invert)
  elseif entity.prototype.fluid_energy_source_prototype then
    calc_util.process_fluid_energy_source(rates, entity, invert)
  elseif entity.prototype.heat_energy_source_prototype then
    calc_util.process_heat_energy_source(rates, entity, invert)
  end

  if entity.burner then
    calc_util.process_burner(rates, entity, invert)
  end
end

--- @param rates MeasureRates
--- @param entities LuaEntity[]
--- @param invert boolean
local function process_entities(rates, entities, invert)
  for _, entity in pairs(entities) do
    process_entity(rates, entity, invert)
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
  local new_set = new_calculation_set()
  table.insert(player_sets, new_set)
  process_entities(new_set.rates, e.entities, false)

  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  gui.show_after_selection(player)
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
    table.insert(player_sets, new_calculation_set())
  end
  local set = player_sets[#player_sets]
  process_entities(set.rates, e.entities, false)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  gui.show_after_selection(player)
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
    table.insert(player_sets, new_calculation_set())
  end
  local set = player_sets[#player_sets]
  process_entities(set.rates, e.entities, true)
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  gui.show_after_selection(player)
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
