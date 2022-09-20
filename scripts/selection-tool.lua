local table = require("__flib__.table")

local constants = require("__RateCalculator__.constants")

local player_data = require("__RateCalculator__.scripts.player-data")
local util = require("__RateCalculator__.scripts.util")

local energy_source_calculators = table.map(constants.energy_source_calculators, function(_, filename)
  return require("__RateCalculator__.scripts.calc.energy-source." .. filename)
end)

local calculators = table.map(constants.entity_data, function(type_data)
  local filename = type_data.calculator
  if filename then
    return require("__RateCalculator__.scripts.calc." .. filename)
  end
end)

local calc_util = require("__RateCalculator__.scripts.calc.util")

local selection_tool = {}

function selection_tool.setup_selection(e, player, player_table, tool_measure, add_to_previous)
  local force = player.force
  local current_research = force.current_research
  local research_data
  if current_research then
    research_data = {
      ingredients = current_research.research_unit_ingredients,
      multiplier = 1 / (current_research.research_unit_energy / 60),
      speed_modifier = force.laboratory_speed_modifier,
    }
  end

  local area = e.area
  local entities = e.entities
  local color = constants.measures[tool_measure].color

  local rates = add_to_previous and player_table.selections[1]
    or table.map(constants.measures, function(_, k)
      if k ~= "all" then
        return {}
      end
    end)

  if #entities > 0 then
    --- @class IterationData
    player_table.iteration_data = {
      add_to_previous = add_to_previous,
      area = area,
      color = color,
      entities = entities,
      measure = tool_measure,
      rates = rates,
      render_objects = {
        rendering.draw_rectangle({
          color = color,
          width = 4,
          filled = false,
          left_top = area.left_top,
          right_bottom = area.right_bottom,
          surface = e.surface,
          players = { player.index },
          draw_on_ground = true,
        }),
      },
      research_data = research_data,
      selected_unpowered_beacon = false,
      surface = e.surface,
    }
    player_data.register_for_iteration(player.index, player_table)
  end
end

function selection_tool.iterate(players_to_iterate)
  local prototypes = {
    entity = game.entity_prototypes,
    fluid = game.fluid_prototypes,
    item = game.item_prototypes,
  }
  local player_tables = global.players
  local iterations_per_player = math.max(global.settings.entities_per_tick / table_size(players_to_iterate), 1)
  for player_index in pairs(players_to_iterate) do
    local player = game.get_player(player_index)
    local player_table = player_tables[player_index]

    local iteration_data = player_table.iteration_data
    local color = iteration_data.color
    local entities = iteration_data.entities
    local rates = iteration_data.rates
    local render_objects = iteration_data.render_objects
    local research_data = iteration_data.research_data
    local surface = iteration_data.surface

    --- @type LuaEntity
    local next_index = table.for_n_of(entities, iteration_data.next_index, iterations_per_player, function(entity)
      if not entity.valid then
        return
      end

      local entity_type = entity.type
      local entity_prototype = entity.prototype

      local emissions_per_second = entity_prototype.emissions_per_second

      -- Process energy source
      for name, calculator in pairs(energy_source_calculators) do
        local data = constants.energy_source_calculators[name]
        if entity_prototype[data.prototype_name] then
          emissions_per_second = calculator(rates[data.measure], entity, emissions_per_second, prototypes)
        end
      end

      -- Process entity-specific logic
      local calculator = calculators[entity_type]
      if calculator then
        emissions_per_second = calculator(rates, entity, emissions_per_second, prototypes, research_data)
          or emissions_per_second
      end

      -- Special entity logic
      if entity_type == "beacon" and entity.status == defines.entity_status.no_power then
        iteration_data.selected_unpowered_beacon = true
      elseif entity_type == "lab" and not research_data then
        iteration_data.selected_lab_without_research = true
      end

      -- Add pollution
      if emissions_per_second ~= 0 then
        calc_util.add_rate(
          rates.pollution,
          emissions_per_second > 0 and "output" or "input",
          "entity",
          entity.name,
          entity.localised_name,
          math.abs(emissions_per_second)
        )
      end

      -- Add indicator dot
      render_objects[#render_objects + 1] = rendering.draw_circle({
        color = color,
        radius = 0.2,
        filled = true,
        target = entity,
        surface = surface,
        players = { player_index },
      })
    end)

    iteration_data.next_index = next_index

    -- If we are done
    if not next_index then
      local selection = iteration_data.rates

      -- This can be slow with large selections, but I say, oh well!
      for _, tbl in pairs(selection) do
        table.sort(tbl, function(a, b)
          return a.outputs.total_amount - a.inputs.total_amount > b.outputs.total_amount - b.inputs.total_amount
        end)
      end

      if iteration_data.add_to_previous then
        -- Replace the frontmost selection
        player_table.selections[1] = selection
      else
        -- Insert at the front and limit number of selections
        table.insert(player_table.selections, 1, selection)
        player_table.selections[constants.save_selections + 1] = nil
      end

      local SelectionGui = util.get_gui(player.index)
      if SelectionGui then
        SelectionGui:update(true, iteration_data.measure ~= "all" and iteration_data.measure)
        SelectionGui:open()
      end

      selection_tool.stop_iteration(player.index, player_table)

      -- We will prioritize unpowered beacons over researchless labs
      if iteration_data.selected_unpowered_beacon then
        util.error_flying_text(player, { "message.rcalc-selected-unpowered-beacon" })
      elseif iteration_data.selected_lab_without_research then
        util.error_flying_text(player, { "message.rcalc-must-be-researching" })
      end

      if player.mod_settings["rcalc-dismiss-tool-on-selection"].value and util.is_rcalc_tool(player.cursor_stack) then
        player.clear_cursor()
      end
    end
  end
end

function selection_tool.stop_iteration(player_index, player_table)
  local objects = player_table.iteration_data.render_objects
  local destroy = rendering.destroy
  for i = 1, #objects do
    destroy(objects[i])
  end
  player_data.deregister_from_iteration(player_index, player_table)
end

return selection_tool
