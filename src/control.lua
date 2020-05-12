local event = require("__flib__.event")
local migration = require("__flib__.migration")

local constants = require("constants")
local migrations = require("scripts.migrations")
local player_data = require("scripts.player-data")

local string = string

if __DebugAdapter then
  __DBGPRINT = __DebugAdapter.print
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

-- PROTOTYPING

event.on_player_selected_area(function(e)
  if e.item == "rcalc-selection-tool" then
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
        end

        entity_data.products = products
      else
        -- TODO
      end

      entity_data.entity = entity
      saved_entities[entity.unit_number] = entity_data
    end
    local breakpoint
  end
end)

event.on_player_alt_selected_area(function(e)

end)