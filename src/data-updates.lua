-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROTOTYPES - UPDATES

-- assemble list of all crafters and beacons
local entities = {}
local entities_index = 0
for _,type in ipairs{'assembling-machine', 'beacon', 'furnace', 'rocket-silo'} do
  for name,_ in pairs(data.raw[type]) do
    entities_index = entities_index + 1
    entities[entities_index] = name
  end
end

-- apply to selection tool
data.raw['selection-tool']['rcalc-selection-tool'].entity_filters = entities