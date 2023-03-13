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
--- @field did_select_lab boolean
--- @field manual_multiplier double
--- @field rates MeasureRates
--- @field research_data ResearchData?
--- @field selected_measure Measure

--- @class ResearchData
--- @field ingredients Ingredient[]
--- @field multiplier double
--- @field speed_modifier double

--- @param player LuaPlayer
--- @return CalculationSet
local function new_calculation_set(player)
  local force = player.force
  local current_research = force.current_research
  --- @type ResearchData?
  local research_data
  if current_research then
    research_data = {
      ingredients = current_research.research_unit_ingredients,
      multiplier = 1 / (current_research.research_unit_energy / 60),
      speed_modifier = force.laboratory_speed_modifier,
    }
  end
  return {
    manual_multiplier = 1,
    rates = {},
    research_data = research_data,
    selected_measure = "per-minute",
  }
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
local function process_entity(set, entity, invert)
  local type = entity.type
  if type == "assembling-machine" or type == "furnace" or type == "rocket-silo" then
    calc_util.process_crafter(set, entity, invert)
  elseif type == "boiler" then
    calc_util.process_boiler(set, entity, invert)
  elseif type == "lab" then
    calc_util.process_lab(set, entity, invert)
  elseif type == "generator" then
    calc_util.process_generator(set, entity, invert)
  elseif type == "mining-drill" then
    calc_util.process_mining_drill(set, entity, invert)
  elseif type == "offshore-pump" then
    calc_util.process_offshore_pump(set, entity, invert)
  elseif type == "reactor" then
    calc_util.process_reactor(set, entity, invert)
  end

  if --[[type == "burner-generator" or]]
    type == "generator"
  then
    calc_util.add_rate(set, "power", "output", "entity", entity.name, entity.prototype.max_power_output * 60, invert)
  elseif type ~= "burner-generator" and entity.prototype.electric_energy_source_prototype then
    calc_util.process_electric_energy_source(set, entity, invert)
  elseif entity.prototype.fluid_energy_source_prototype then
    calc_util.process_fluid_energy_source(set, entity, invert)
  elseif entity.prototype.heat_energy_source_prototype then
    calc_util.process_heat_energy_source(set, entity, invert)
  end

  if entity.burner then
    calc_util.process_burner(set, entity, invert)
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
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local player_sets = table.get_or_insert(global.calculation_sets, e.player_index, {})
  local new_set = new_calculation_set(player)
  table.insert(player_sets, new_set)
  process_entities(new_set, e.entities, false)

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
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local player_sets = table.get_or_insert(global.calculation_sets, e.player_index, {})
  if not next(player_sets) then
    table.insert(player_sets, new_calculation_set(player))
  end
  local set = player_sets[#player_sets]
  process_entities(set, e.entities, false)
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
  local player = game.get_player(e.player_index)
  if not player then
    return
  end
  local player_sets = table.get_or_insert(global.calculation_sets, e.player_index, {})
  if not next(player_sets) then
    table.insert(player_sets, new_calculation_set(player))
  end
  local set = player_sets[#player_sets]
  process_entities(set, e.entities, true)
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
