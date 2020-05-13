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

  local entities = e.entities
  local ingredients = {}
  local products = {}

  for i = 1, #entities do
    local entity = entities[i]
    local recipe = entity.get_recipe()

    if recipe then
      local ingredient_base_unit = (60 / recipe.energy) * entity.crafting_speed
      for _, ingredient in ipairs(recipe.ingredients) do
        local combined_name = ingredient.type..","..ingredient.name
        local ingredient_data = ingredients[combined_name]
        local amount = ingredient.amount * ingredient_base_unit
        if ingredient_data then
          ingredient_data.amount = ingredient_data.amount + amount
        else
          ingredients[combined_name] = {type=ingredient.type, name=ingredient.name, amount=amount}
        end
      end

      local product_base_unit = ingredient_base_unit * (entity.productivity_bonus + 1)
      for _, product in ipairs(recipe.products) do
        local base_unit = product_base_unit * (product.probability or 1)

        local amount = product.amount
        if amount then
          amount = amount * base_unit
        else
          amount = (product.amount_max - ((product.amount_max - product.amount_min) / 2)) * base_unit
        end

        local combined_name = product.type..","..product.name
        local product_data = products[combined_name]
        if product_data then
          product_data.amount = product_data.amount + amount
        else
          products[combined_name] = {type=product.type, name=product.name, amount=amount}
        end
      end
    end
  end

  log(serpent.block{inputs=ingredients, outputs=products})
end)

event.on_player_alt_selected_area(function(e)
  -- TODO cancel selection
end)