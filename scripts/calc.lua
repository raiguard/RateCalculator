local rates_set = require("scripts.rates-set")
local rates_set_manager = require("scripts.rates-set-manager")

local sw = require("__sw-rates-lib__.api-usage")

local gui = require("scripts.gui")

--- @class Set<T>: { [T]: boolean }

--- @class CalculationSet
--- @field completed Set<string>
--- @field player LuaPlayer
--- @field rates table<string, Rates>

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

--- @class CachedConfig
--- @field config Rates.Configuration
--- @field production Rates.Configuration.Amount[]
--- @field description Rates.Gui.NodeDescription

--- @param set RatesSet
--- @param entities LuaEntity[]
--- @param invert boolean
local function process_entities(set, entities, invert)
  for _, entity in pairs(entities) do
    local config = sw.configuration.get_from_entity(entity, { use_ghosts = true })
    if not config then
      goto continue
    end

    local cached_config = set:add_configuration(config, entity.force --[[@as LuaForce]], entity.surface)
    set:add_rates(cached_config, invert)

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

  local set = rates_set.new()
  process_entities(set, e.entities, false)
  if set:is_empty() then
    -- TODO: Show flying text?
    return
  end

  storage.rates_set_manager:add(set, e.player_index)

  -- gui.build_and_show(player, set, true)

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

  local new_set = false
  local set = storage.rates_set_manager:get_active(e.player_index)
  if not set then
    new_set = true
    set = rates_set.new()
  end

  process_entities(set, e.entities, false)

  if set:is_empty() then
    return
  end

  if new_set then
    storage.rates_set_manager:add(set, e.player_index)
  end

  -- gui.build_and_show(player, set)
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

  local set = storage.rates_set_manager:get_active(e.player_index)
  if not set then
    return
  end

  process_entities(set, e.entities, true)

  if set:is_empty() then
    -- TODO: Delete set
    return
  end

  -- gui.build_and_show(player, set)
end

--- @class Calc
local calc = {}

function calc.on_init()
  storage.rates_set_manager = rates_set_manager.new()
end

-- TODO: Preserve sets across mod changes and migrate things as needed
calc.on_configuration_changed = calc.on_init

calc.events = {
  [defines.events.on_player_alt_reverse_selected_area] = on_player_alt_reverse_selected_area,
  [defines.events.on_player_alt_selected_area] = on_player_alt_selected_area,
  [defines.events.on_player_selected_area] = on_player_selected_area,
}

return calc
