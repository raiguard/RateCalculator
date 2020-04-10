-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROTOTYPES - UPDATES

-- assemble list of all crafters
local crafters = {}
local crafters_index = 0
for _,type in ipairs{'assembling-machine', 'furnace', 'rocket-silo'} do
  for name,_ in pairs(data.raw[type]) do
    crafters_index = crafters_index + 1
    crafters[crafters_index] = name
  end
end

-- apply to selection tool
data.raw['selection-tool']['rcalc-selection-tool'].entity_filters = crafters