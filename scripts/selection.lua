-- Instead of processing the entities immediately into a rates set, store the entities and their properties
-- so we can manipulate them as required. Don't store the LuaEntity itself because things could change.

--- @class SelectionSet
--- @field entities EntityData[]
--- @field research_data ResearchData?

--- @class EntityData
--- @field consumption_bonus double
--- @field entity LuaEntityPrototype
--- @field fuel FuelPrototype?
--- @field productivity_bonus double
--- @field recipe LuaRecipe?
--- @field speed_bonus double

--- @class FluidPrototypeWithTemperature
--- @field fluid LuaFluidPrototype
--- @field temperature double
--- @alias FuelPrototype FluidPrototypeWithTemperature|LuaItemPrototype

--- @param entity LuaEntity
--- @return FuelPrototype?
local function get_fuel(entity)
  local prototype = entity.prototype
  if entity.type == "generator" then
    -- TODO:
  elseif prototype.electric_energy_source_prototype or prototype.heat_energy_source_prototype then
    return
  elseif prototype.burner_prototype then
    return entity.burner.currently_burning
  elseif prototype.fluid_energy_source_prototype then
    -- The fluid energy source fluidbox will always be the last one
    local fluidbox = entity.fluidbox
    local fluid = fluidbox[#fluidbox]
    if fluid then
      return { fluid = game.fluid_prototypes[fluid.name], temperature = fluid.temperature }
    end
  end
end

--- @param set SelectionSet
--- @param entity LuaEntity
--- @param invert boolean
local function process_entity(set, entity, invert)
  local prototype = entity.prototype
  table.insert(set, {
    consumption_bonus = entity.consumption_bonus,
    entity = prototype,
    fuel = get_fuel(entity),
    productivity_bonus = entity.productivity_bonus,
    recipe = entity.get_recipe(),
    speed_bonus = entity.speed_bonus,
  })
end

--- @param set SelectionSet
--- @param entities LuaEntity[]
--- @param invert boolean
local function process_entities(set, entities, invert)
  for _, entity in pairs(entities) do
    process_entity(set, entity, invert)
  end
end

--- @param force LuaForce
--- @return SelectionSet
local function new_selection(force)
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
    entities = {},
    research_data = research_data,
  }
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
  local set = new_selection(player.force --[[@as LuaForce]])
  process_entities(set, e.entities, false)
end

local selection = {}

selection.events = {
  [defines.events.on_player_selected_area] = on_player_selected_area,
}

return selection
