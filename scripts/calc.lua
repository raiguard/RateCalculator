local calc_util = require("scripts.calc-util")
local gui = require("scripts.gui")
local LP = require("scripts.configurator")

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
--- @field recipes table<string, {items: table<string, number>}>
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
    recipes = {}, -- Store per-recipe I/O summary here
  }
end

--- @param set CalculationSet
local function run_solver(set)
  -- Log summed rates for the whole selection
  for path, rates in pairs(set.rates) do
    local input_rate = rates.input and rates.input.rate or 0
    local output_rate = rates.output and rates.output.rate or 0
    local net = output_rate - input_rate
    local disp_type = rates.type or "?"
    local disp_name = rates.name or "?"
  end

  local raw_inputs = {}
  local final_products = {}
  if set.recipes then
    -- Categorize recipe items as RawInputs, Intermediates, FinalProducts
    local input_items = {}  -- items seen as inputs (rate<0)
    local output_items = {} -- items seen as outputs (rate>0)
    for _, recipe_info in pairs(set.recipes) do
      for itemname, rate in pairs(recipe_info.items) do
        if rate < 0 then
          input_items[itemname] = true
        end
        if rate > 0 then
          output_items[itemname] = true
        end
      end
    end
    local intermediates = {}
    for itemname, _ in pairs(input_items) do
      if not output_items[itemname] then
        table.insert(raw_inputs, itemname)
      else
        table.insert(intermediates, itemname)
      end
    end
    for itemname, _ in pairs(output_items) do
      if not input_items[itemname] then
        table.insert(final_products, itemname)
      end
    end
    -- Sort for easier reading
    table.sort(raw_inputs)
    table.sort(intermediates)
    table.sort(final_products)
  end

  -- Build LP model and solve
  if not set.recipes or not next(set.recipes) then
    return
  end

  local lp = LP.new_lp_problem()

  -- Add each real recipe
  for recipe_name, recipe_info in pairs(set.recipes) do
    local entries = {}
    for itemname, rate in pairs(recipe_info.items) do
      table.insert(entries, { itemname, rate })
    end
    LP.add_recipe(lp, recipe_name, entries)
  end

  -- Add pseudo-recipe for each RawInput, named "raw-<item>"
  for _, raw_item in ipairs(raw_inputs) do
    LP.add_recipe(lp, "raw-" .. raw_item, { { raw_item, 1 } })
  end

  -- For real recipes only, set upper bound to 1.0
  for recipe_name, _ in pairs(set.recipes) do
    LP.set_upper(lp, recipe_name, 1.0)
  end

  -- For every FinalProduct, maximize all real recipes that produce it (weight 1)
  for _, final_item in ipairs(final_products) do
    for recipe_name, recipe_info in pairs(set.recipes) do
      if recipe_info.items[final_item] and recipe_info.items[final_item] > 0 then
        -- if a single recipe produces multiple FinalProducts, the last maximize call will
        -- overwrite the others; this is fine
        LP.optimize(lp, recipe_name, 1, LP.ObjectiveDirection.MAXIMIZE)
      end
    end
  end

  -- Finalize, store LP result, and mark any failure
  local status, solution, objective = LP.finalize(lp)
  set.lp_status = status
  if type(solution) == "table" then
    -- build a summary of produced vs consumed for each item
    local summary = {}
    for recipe_name, recipe_rate in pairs(solution) do
      -- only real recipes are in set.recipes
      local recipe = set.recipes[recipe_name]
      if recipe then
        for item_name, coef in pairs(recipe.items) do
          local entry = summary[item_name] or { produced = 0, consumed = 0 }
          local delta = coef * recipe_rate
          if delta > 0 then
            entry.produced = entry.produced + delta
          elseif delta < 0 then
            -- make consumed a positive number
            entry.consumed = entry.consumed - delta
          end
          summary[item_name] = entry
        end
      end
    end
    set.simplex = summary
  else
    -- on failure, zero‐out rates in GUI and flag an error
    set.solution = {}
    set.errors["simplex-failed"] = true
  end
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
  for _, entity in pairs(entities) do
    process_entity(set, entity, invert)
  end
  run_solver(set)
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
