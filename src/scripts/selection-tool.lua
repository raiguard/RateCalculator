local table = require("__flib__.table")

local player_data = require("scripts.player-data")

local calc_electric_energy_interface = require("scripts.calc.electric-energy-interface")
local calc_drill = require("scripts.calc.drill")
local calc_energy = require("scripts.calc.energy")
local calc_generator = require("scripts.calc.generator")
local calc_lab = require("scripts.calc.lab")
local calc_offshore_pump = require("scripts.calc.offshore-pump")
local calc_recipe = require("scripts.calc.recipe")

local calc_materials = {
  ["assembling-machine"] = calc_recipe,
  ["electric-energy-interface"] = calc_electric_energy_interface,
  ["furnace"] = calc_recipe,
  ["generator"] = calc_generator,
  ["lab"] = calc_lab,
  ["mining-drill"] = calc_drill,
  ["offshore-pump"] = calc_offshore_pump,
  ["rocket-silo"] = calc_recipe,
}

local selection_tool = {}

function selection_tool.setup_selection(player, player_table, area, entities, surface)
  local force = player.force
  local current_research = force.current_research
  local research_data
  if current_research then
    research_data = {
      ingredients = current_research.research_unit_ingredients,
      multiplier = 1 / (current_research.research_unit_energy / 60),
      speed_modifier = force.laboratory_speed_modifier
    }
  end

  if #entities > 0 then
    player_table.iteration_data = {
      area = area,
      entities = entities,
      rate_data = {inputs = {__size = 0}, outputs = {__size = 0}},
      render_objects = {
        rendering.draw_rectangle{
          color = {r = 1, g = 1, b = 0},
          width = 4,
          filled = false,
          left_top = area.left_top,
          right_bottom = area.right_bottom,
          surface = surface,
          players = {player.index},
          draw_on_ground = true
        }
      },
      research_data = research_data,
      started_tick = game.tick,
      surface = surface
    }
    player_data.register_for_iteration(player.index, player_table)
    return true -- register on_tick
  end
end

function selection_tool.iterate(players_to_iterate)
  local prototypes = {
    entity = game.entity_prototypes,
    fluid = game.fluid_prototypes,
    item = game.item_prototypes
  }
  local player_tables = global.players
  local iterations_per_player = math.max(global.settings.entities_per_tick / table_size(players_to_iterate), 1)
  for player_index in pairs(players_to_iterate) do
    local player = game.get_player(player_index)
    local player_table = player_tables[player_index]
    local iteration_data = player_table.iteration_data
    local entities = iteration_data.entities
    local rates = iteration_data.rate_data
    local research_data = iteration_data.research_data
    local render_objects = iteration_data.render_objects
    local surface = iteration_data.surface

    local next_index = table.for_n_of(entities, iteration_data.next_index, iterations_per_player, function(entity)
      if not entity.valid then return end

      -- process entity
      calc_energy(rates, entity)
      calc_materials[entity.type](rates, entity, prototypes, research_data)

      -- add indicator dot
      render_objects[#render_objects+1] = rendering.draw_circle{
        color = {r = 1, g = 1, b = 0},
        radius = 0.2,
        filled = true,
        target = entity,
        surface = surface,
        players = {player_index}
      }
    end)

    if next_index then
      iteration_data.next_index = next_index
    else
      if rates.inputs.__size == 0 and rates.outputs.__size == 0 then
        player.print{"rcalc-message.no-compatible-machines-in-selection"}
      else
        rates.inputs.__size = nil
        rates.outputs.__size = nil
        local function sorter(a, b)
          return a.amount > b.amount
        end
        -- this is an ugly horrible dirty way to convert a table into an array (loses key references)
        local sorted_data = {
          inputs = table.filter(rates.inputs, function() return true end, true),
          outputs = table.filter(rates.outputs, function() return true end, true)
        }
        table.sort(sorted_data.inputs, sorter)
        table.sort(sorted_data.outputs, sorter)
        player_table.selection_data = {
          sorted = sorted_data,
          hash = rates
        }

        -- rcalc_gui.update_contents(player_table)
        if not player_table.flags.gui_open then
          -- rcalc_gui.open(player, player_table)
        end
      end
      selection_tool.stop_iteration(player.index, player_table)
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
