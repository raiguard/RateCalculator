local calc_util = require("scripts.calc-util")

local api = require("__sw-rates-lib__.api-usage")

local gui = require("scripts.gui")

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
--- @field rates table<string, Rates>
--- @field research_data ResearchData?
--- @field pollutant string

--- @alias MachineCounts table<string, uint>

--- @class Rate
--- @field machine_counts MachineCounts
--- @field machines integer
--- @field rate double

--- @class Rates
--- @field type string
--- @field name string
--- @field quality string?
--- @field temperature double?
--- @field output Rate
--- @field input Rate

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
  local pollutant = ""
  local pollutant_prototype = player.surface.pollutant_type
  if pollutant_prototype then
    pollutant = pollutant_prototype.name
  end
  return {
    completed = {},
    errors = {},
    player = player,
    rates = {},
    research_data = research_data,
    pollutant = pollutant,
  }
end

local entity_blacklist = {
  -- Transport Drones
  ["buffer-depot"] = true,
  ["fluid-depot"] = true,
  ["fuel-depot"] = true,
  ["request-depot"] = true,
}

--- @param set CalculationSet
--- @param entity LuaEntity
--- @param invert boolean
local function process_entity(set, entity, invert)
  if entity_blacklist[entity.name] then
    return
  end

  local emissions_per_second = entity.prototype.emissions_per_second[set.pollutant] or 0
  local type = entity.type

  if type == "burner-generator" or type == "generator" then
    calc_util.add_rate(
      set,
      "output",
      "item",
      "rcalc-power-dummy",
      "normal",
      entity.prototype.get_max_power_output(entity.quality) * 60,
      invert,
      entity.name
    )
  elseif type ~= "burner-generator" and entity.prototype.electric_energy_source_prototype then
    emissions_per_second = calc_util.process_electric_energy_source(set, entity, invert, emissions_per_second)
  elseif entity.prototype.fluid_energy_source_prototype then
    emissions_per_second = calc_util.process_fluid_energy_source(set, entity, invert, emissions_per_second)
  elseif entity.prototype.heat_energy_source_prototype then
    calc_util.process_heat_energy_source(set, entity, invert)
  end

  if entity.burner then
    emissions_per_second = calc_util.process_burner(set, entity, invert, emissions_per_second)
  end

  if type == "assembling-machine" or type == "furnace" or type == "rocket-silo" then
    emissions_per_second = calc_util.process_crafter(set, entity, invert, emissions_per_second)
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

  if emissions_per_second > 0 then
    calc_util.add_rate(
      set,
      "output",
      "item",
      "rcalc-pollution-dummy",
      "normal",
      emissions_per_second,
      invert,
      entity.name
    )
  elseif emissions_per_second < 0 then
    calc_util.add_rate(
      set,
      "input",
      "item",
      "rcalc-pollution-dummy",
      "normal",
      -emissions_per_second,
      invert,
      entity.name
    )
  end
end

--- @param set CalculationSet
--- @param entities LuaEntity[]
--- @param invert boolean
local function process_entities(set, entities, invert)
  local force = set.player.force --[[@as LuaForce]]
  for _, entity in pairs(entities) do
    local config = api.configuration.get_from_entity(entity, { use_ghosts = true })
    if not config then
      goto continue
    end
    local production = api.configuration.get_production(config, { force = force })
    local config_entity = api.configuration.gui_entity(config)
    for _, amount in pairs(production) do
      game.print(serpent.line(amount))
      local category = amount.amount > 0 and "output" or "input"
      -- TODO: Handle all kinds of nodes
      -- TODO: Handle fuels differently
      if amount.node.type == "item" or amount.node.type == "item-fuel" then
        calc_util.add_rate(
          set,
          category,
          "item",
          amount.node.item.name,
          amount.node.quality.name,
          math.abs(amount.amount),
          invert,
          config_entity.element.name
        )
      elseif amount.node.type == "fluid" or amount.node.type == "fluid-fuel" then
        calc_util.add_rate(
          set,
          category,
          "fluid",
          amount.node.fluid.name,
          "normal",
          math.abs(amount.amount),
          invert,
          config_entity.element.name,
          amount.node.temperature
        )
      end
    end
    ::continue::
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
  gui.build_and_show(player, set, true)
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
  gui.build_and_show(player, set)
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
  gui.build_and_show(player, set)
end

--- @class Calc
local calc = {}

calc.events = {
  [defines.events.on_player_alt_reverse_selected_area] = on_player_alt_reverse_selected_area,
  [defines.events.on_player_alt_selected_area] = on_player_alt_selected_area,
  [defines.events.on_player_selected_area] = on_player_selected_area,
}

return calc
