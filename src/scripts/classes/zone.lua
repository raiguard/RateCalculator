-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ZONE CLASS

-- module
local zone = {}

-- class
local Zone = {}

-- dependencies
local Entity = require("scripts.classes.entity")

function Zone:iterate_entities()
  local entities = self.entities
  
end

function zone.new(area, entities, player, surface)
  local self = {}
  setmetatable(self, {__index = Zone})
  self.area = area
  self.player = player
  self.surface = surface

  -- init entities
  self.entities = {}
  for _,entity in ipairs(entities) do
    self.entities[entity.unit_number] = Entity.new(entity, player)
  end

  -- iterate entities
  self:iterate_entities()

  return self
end

return zone