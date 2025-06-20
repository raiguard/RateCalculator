local calc_util = require("scripts.calc-util")

local api = require("__sw-rates-lib__.api-usage")

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

--- @param player LuaPlayer
--- @return CalculationSet
local function new_calculation_set(player)
  return {
    completed = {},
    player = player,
    rates = {},
  }
end

--- @param set CalculationSet
--- @param entities LuaEntity[]
--- @param invert boolean
local function process_entities(set, entities, invert)
  local force = set.player.force --[[@as LuaForce]]
  local surface = set.player.surface
  --- @type table<string, {config: Rates.Configuration, production: Rates.Configuration.Amount[], description: Rates.Gui.NodeDescription}>
  local config_cache = {}
  for _, entity in pairs(entities) do
    local config = api.configuration.get_from_entity(entity, { use_ghosts = true })
    if not config then
      goto continue
    end
    local config_id = api.configuration.get_id(config)
    local info = config_cache[config_id]
    if not info then
      info = {
        config = config,
        production = api.configuration.get_production(
          config,
          { apply_quality = true, force = force, surface = surface, use_pollution = true }
        ),
        description = api.configuration.gui_entity(config),
      }
      config_cache[config_id] = info
    end
    local description = info.description
    -- log(serpent.block(config))
    -- log(serpent.block(production))
    -- log(serpent.block(config_entity))
    -- log(serpent.block(api.configuration.gui_recipe(config)))
    local entity_id = description.element.name .. "/" .. (description.element.quality or "normal")
    for _, amount in pairs(info.production) do
      local category = amount.amount > 0 and "output" or "input"
      local node = amount.node
      local node_type = node.type

      if node_type == "agricultural-cell" then
        -- Ignore
      elseif node_type == "any" then
        local details = node.details
        if details then
          local details_type = details.type
          if details_type == "any-fluid" then
            calc_util.add_rate(
              set,
              category,
              "fluid",
              details.fluid.name,
              "normal",
              math.abs(amount.amount),
              invert,
              entity_id
            )
          elseif details_type == "any-heat" then
            calc_util.add_rate(
              set,
              category,
              "item",
              "rcalc-heat-dummy",
              "normal",
              math.abs(amount.amount),
              invert,
              entity_id
            )
          elseif details_type == "any-item-fuel" then
            game.print("TODO: " .. serpent.line(amount))
          end
        end
      elseif node_type == "electric-buffer" then
        calc_util.add_rate(
          set,
          category,
          "item",
          "rcalc-electric-energy-buffer-dummy",
          "normal",
          math.abs(amount.amount),
          invert,
          entity_id
        )
      elseif node_type == "electric-power" then
        calc_util.add_rate(
          set,
          category,
          "item",
          "rcalc-electric-power-dummy",
          "normal",
          math.abs(amount.amount),
          invert,
          entity_id
        )
      elseif node_type == "fluid" and node.fluid then
        calc_util.add_rate(
          set,
          category,
          "fluid",
          node.fluid.name,
          "normal",
          math.abs(amount.amount),
          invert,
          entity_id,
          node.temperature
        )
      elseif node_type == "fluid-fuel" then
        calc_util.add_rate(
          set,
          category,
          "fluid",
          "rcalc-fluid-fuel-dummy",
          "normal",
          math.abs(amount.amount),
          invert,
          entity_id
        )
      elseif node_type == "heat" then
        calc_util.add_rate(
          set,
          category,
          "item",
          "rcalc-heat-dummy",
          "normal",
          math.abs(amount.amount),
          invert,
          entity_id,
          node.temperature
        )
      elseif node_type == "item" and node.item then
        calc_util.add_rate(
          set,
          category,
          "item",
          node.item.name,
          node.quality.name,
          math.abs(amount.amount),
          invert,
          entity_id
        )
      elseif node_type == "item-fuel" then
        calc_util.add_rate(
          set,
          category,
          "item",
          "rcalc-item-fuel-dummy",
          "normal",
          math.abs(amount.amount),
          invert,
          entity_id
        )
      elseif node_type == "send-to-orbit" then
        calc_util.add_rate(
          set,
          category,
          "item",
          "rcalc-rocket-to-orbit-dummy",
          "normal",
          math.abs(amount.amount),
          invert,
          entity_id
        )
      elseif node_type == "map-entity" then
        -- Ignore
      elseif node_type == "pollution" then
        calc_util.add_rate(
          set,
          category,
          "item",
          "rcalc-pollution-dummy",
          "normal",
          math.abs(amount.amount),
          invert,
          entity_id
        )
      elseif node_type == "science" then
        -- Ignore
      elseif node_type == "send-to-platform" then
        calc_util.add_rate(
          set,
          category,
          "item",
          "rcalc-rocket-to-platform-dummy",
          "normal",
          math.abs(amount.amount),
          invert,
          entity_id
        )
      elseif node_type == "thrust" then
        calc_util.add_rate(
          set,
          category,
          "item",
          "rcalc-thrust-dummy",
          "normal",
          math.abs(amount.amount),
          invert,
          entity_id
        )
      else
        game.print("UNKNOWN NODE TYPE: " .. serpent.line(amount))
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
