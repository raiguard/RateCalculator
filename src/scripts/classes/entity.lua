-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ENTITY CLASS

-- module
local entity = {}

-- class table
local Entity = {}



function entity.new(entity, player)
  local self = {}
  setmetatable(self, {__index = Entity})
  self.entity = entity
  self.player_index = player.index
  return self
end

return entity