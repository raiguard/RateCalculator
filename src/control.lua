local event = require("__flib__.event")
local migration = require("__flib__.migration")

local constants = require("constants")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")

local math = math
local string = string

if __DebugAdapter then
  __DBGPRINT = __DebugAdapter.print
end

local function round(num, num_decimals)
  local mult = 10^(num_decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function add_positions(positions)
  local pos1 = positions[1]
  for i = 2, #positions do
    local pos2 = positions[i]
    pos1 = {x=(pos1.x + pos2.x), y=(pos1.y + pos2.y)}
  end
  return pos1
end

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

event.on_init(function()
  global.beacons = {}
  global.crafters = {}
  global.players = {}
  for i, player in pairs(game.players) do
    player_data.init(i, player)
  end
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    -- refresh player data
    for i, player in pairs(game.players) do
      player_data.refresh(player, global.players[i])
    end
  end
end)

event.on_player_created(function(e)
  player_data.init(e.player_index, game.get_player(e.player_index))
end)

-- ! PROTOTYPING

event.on_player_selected_area(function(e)
  if e.item ~= "rcalc-selection-tool" then return end

  local player = game.get_player(e.player_index)
  local entities = e.entities
  local product_lookup = {}
  local saved_entities = {}

  for i = 1, #entities do
    local entity = entities[i]
    local recipe = entity.get_recipe()

    local entity_data = {}

    if recipe then
      local crafting_speed = entity.crafting_speed
      local productivity_bonus = entity.productivity_bonus
      local base_unit = (60 / recipe.energy) * crafting_speed * (productivity_bonus + 1)

      local products = {}
      for product_index, product in ipairs(recipe.products) do
        -- TODO handle min and max amounts, probabilities
        local rate_per_minute = product.amount * base_unit
        product.rate_per_minute = rate_per_minute
        products[product_index] = product

        local lookup_data = product_lookup[product.name]
        if lookup_data then
          product_lookup[product.name] = lookup_data + rate_per_minute
        else
          product_lookup[product.name] = rate_per_minute
        end

        -- ! PROTOTYPE RENDERING
        local box = entity.bounding_box
        -- local width = box.right_bottom.x - box.left_top.x
        -- local height = box.right_bottom.y - box.left_top.y
        -- local background_scale = 0.8 * math.min(width, height)
        local initial_offset = {x=0.4, y=0.25}
        local offset = product_index - 1
        -- TODO fixed precision format
        rendering.draw_rectangle{
          color = {10,10,10,200},
          filled = true,
          left_top = add_positions{box.left_top, initial_offset, {x=-0.35, y=-0.35}, {x=0, y=(offset * 0.5)}},
          right_bottom = add_positions{box.left_top, initial_offset, {x=0.1, y=0.1}, {x=0, y=(offset * 0.5)}, {x=2, y=0.3}},
          surface = entity.surface,
          time_to_live = 120
        }
        rendering.bring_to_front(rendering.draw_sprite{
          sprite = product.type.."/"..product.name,
          target = add_positions{box.left_top, initial_offset, {x=0, y=(offset * 0.5)}},
          surface = entity.surface,
          time_to_live = 120,
          x_scale = 0.6,
          y_scale = 0.6
        })
        rendering.draw_text{
          text = round(product.rate_per_minute, 3).." / m",
          surface = entity.surface,
          target = add_positions{box.left_top, initial_offset, {x=0.4, y=-0.3}, {x=0, y=(offset * 0.5)}},
          color = {255,255,255},
          time_to_live = 120
        }
      end

      entity_data.products = products
    else
      -- TODO
    end

    entity_data.entity = entity
    saved_entities[entity.unit_number] = entity_data
  end
  local breakpoint
end)

event.on_player_alt_selected_area(function(e)
  -- TODO cancel selection
end)