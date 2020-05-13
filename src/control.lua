local event = require("__flib__.event")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")

local constants = require("constants")

local global_data = require("scripts.global-data")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")
local rcalc_gui = require("scripts.rcalc-gui")

local math = math
local string = string

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS

event.on_init(function()
  gui.init()

  global_data.init()
  for i, player in pairs(game.players) do
    player_data.init(i, player)
  end

  gui.build_lookup_tables()
end)

event.on_load(function()
  gui.build_lookup_tables()
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

event.on_player_selected_area(function(e)
  if e.item ~= "rcalc-selection-tool" then return end

  -- TODO move to another file
  local entities = e.entities
  local ingredients = {__size=0}
  local products = {__size=0}

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
          ingredients.__size = ingredients.__size + 1
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
          products.__size = products.__size + 1
        end
      end
    end
  end

  local player = game.get_player(e.player_index)

  if ingredients.__size == 0 and products.__size == 0 then
    player.print{"rcalc-message.no-recipes-in-selection"}
  else
    local player_table = global.players[e.player_index]
    if player_table.flags.gui_open then
      rcalc_gui.destroy(player, player_table)
    end
    rcalc_gui.create(player, player_table, {ingredients=ingredients, products=products})
  end
end)

event.on_player_alt_selected_area(function(e)
  -- TODO cancel selection
end)