local calc_util = require("__RateCalculator__/scripts/calc-util")

local gui = require("__RateCalculator__/scripts/gui")

--- @class Set<T>: { [T]: boolean }

--- @alias CalculationError
--- | "max-crafting-speed"
--- | "incompatible-science-packs"
--- | "no-active-research"
--- | "no-input-fluid"
--- | "no-fuel"
--- | "no-mineable-resources"
--- | "no-power"
--- | "no-recipe"

--- @class CalculationSet
--- @field completed Set<string>
--- @field errors Set<CalculationError>
--- @field player LuaPlayer
--- @field rates Rates
--- @field research_data ResearchData?

--- @alias Rates table<string, RatesSet>

--- @class RatesSet
--- @field input double
--- @field input_machine_counts table<string, uint>
--- @field input_machines uint
--- @field name string
--- @field output double
--- @field output_machine_counts table<string, uint>
--- @field output_machines uint
--- @field type string

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
    completed = {},
    errors = {},
    player = player,
    rates = {},
    research_data = research_data,
  }
end

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
local function process_entity(set, entity, invert)
  local type = entity.type
  if type == "assembling-machine" or type == "furnace" or type == "rocket-silo" then
    calc_util.process_crafter(set, entity, invert)
  elseif type == "beacon" then
    calc_util.process_beacon(set, entity)
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

  if type == "burner-generator" or type == "generator" then
    calc_util.add_rate(
      set,
      "output",
      "item",
      "rcalc-power-dummy",
      entity.prototype.max_power_output * 60,
      invert,
      entity.name
    )
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
  local set = new_calculation_set(player)
  process_entities(set, e.entities, false)
  gui.show(player, set, true)
  if player.mod_settings["rcalc-dismiss-tool-on-selection"].value then
    player.clear_cursor()
  end
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
  local set = gui.get_current_set(player)
  if not set then
    set = new_calculation_set(player)
  end
  set.errors = {}
  process_entities(set, e.entities, false)
  gui.show(player, set, false)
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
  local set = gui.get_current_set(player)
  if not set then
    set = new_calculation_set(player)
  end
  set.errors = {}
  process_entities(set, e.entities, true)
  gui.show(player, set, false)
end

--- @class Calc
local calc = {}

calc.events = {
  [defines.events.on_player_alt_reverse_selected_area] = on_player_alt_reverse_selected_area,
  [defines.events.on_player_alt_selected_area] = on_player_alt_selected_area,
  [defines.events.on_player_selected_area] = on_player_selected_area,
}

return calc
