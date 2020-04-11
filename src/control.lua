-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONTROL SCRIPTING

-- depencencies
local event = require("__RaiLuaLib__.lualib.event")
local migration = require("__RaiLuaLib__.lualib.migration")

-- locals
local string_gsub = string.gsub
local string_sub = string.sub

local crafter_types = {["assembling-machine"] = true, ["furnace"] = true, ["rocket-silo"] = true}

-- classes
local Zone = require("scripts.classes.zone")

-- custom create_from_center function, omitting ensure_xy and using the radius instead of the width
local function create_from_center(position, radius)
  return {
    left_top = {x=position.x-radius, y=position.y-radius},
    right_bottom = {x=position.x+radius, y=position.y+radius}
  }
end

-- custom collides function, omitting ensure_xy since those are already gauranteed
local function collides_with(box1, box2)
  return box1.left_top.x < box2.right_bottom.x and
    box2.left_top.x < box1.right_bottom.x and
    box1.left_top.y < box2.right_bottom.y and
    box2.left_top.y < box1.right_bottom.y
end

-- -----------------------------------------------------------------------------
-- PLAYER DATA

local function setup_player(index, player)
  global.players[index] = {
    dictionary = {},
    flags = {},
    gui = {},
    regions = {},
    settings = {}
  }
end

local function import_player_settings(player, player_table)
  local settings = {}
  for name,t in pairs(player.mod_settings) do
    if string_sub(name, 1, 5) == "rcalc-" then
      settings[string_gsub(string_gsub(name, "rcalc%-", ""), "%-", "_")] = t.value
    end
  end
  player_table.settings = settings
end

local function refresh_player_data(player, player_table)
  -- TODO: close all GUIs
  -- refresh settings
  import_player_settings(player, player_table)
end

-- -----------------------------------------------------------------------------
-- STATIC HANDLERS

event.on_init(function()
  global.beacons = {}
  global.crafters = {}
  global.players = {}
  for i,p in pairs(game.players) do
    setup_player(i)
    refresh_player_data(p, global.players[i])
  end
end)

event.on_player_created(function(e)
  setup_player(e.player_index, game.get_player(e.player_index))
end)

-- PROTOTYPING

event.on_player_selected_area(function(e)
  if e.item == 'rcalc-selection-tool' then
    local player = game.get_player(e.player_index)
    local entities = e.entities
    if #entities > 0 then
      -- Zone.new(e.area, e.entities, player, player.surface)
      -- prototype entity iteration - really bad for performance!

      -- first pass - create lookup table by unit number
      local entities_by_number = {}
      for i=1,#entities do
        local entity = entities[i]
        entities_by_number[entity.unit_number] = entity
      end

      -- second pass - assemble bounding box tables
      local beacon_boxes = {}
      local crafter_boxes = {}
      for i=1,#entities do
        local entity = entities[i]
        if entity.type == "beacon" then
          beacon_boxes[entity.unit_number] = create_from_center(entity.position, entity.prototype.supply_area_distance + entity.prototype.radius)
        else
          crafter_boxes[entity.unit_number] = entity.selection_box
        end
      end

      -- third pass - assign beacons to crafters based on bounding box overlaps
      local beacons_by_crafter = {}
      local profiler = game.create_profiler()
      for beacon_un, beacon_box in pairs(beacon_boxes) do
        for crafter_un, crafter_box in pairs(crafter_boxes) do
          if collides_with(crafter_box, beacon_box) then
            local list = beacons_by_crafter[crafter_un]
            if list then
              list[#list+1] = beacon_un
            else
              beacons_by_crafter[crafter_un] = {beacon_un}
            end
          end
        end
      end
      profiler.stop()
      log(profiler)

      -- DEBUG
      for unit_number, entity in pairs(entities_by_number) do
        if entity.type ~= "beacon" then
          rendering.draw_text{text=entity.crafting_speed, target=entity.position, surface=entity.surface, color={r=1,g=1,b=1,a=1}}
        end
      end

      -- fourth pass - calculate material rates for each assembling machine
      
    end
  end
end)

event.on_player_alt_selected_area(function(e)

end)

-- -----------------------------------------------------------------------------
-- MIGRATIONS

local migrations = {}

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    -- refresh player data
    for i,p in pairs(game.players) do
      refresh_player_data(p, global.players[i])
    end
  end
end)