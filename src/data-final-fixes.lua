local table = require("__flib__.table")

local constants = require("constants")

local entities = table.map(constants.selection_tools, function() return {} end)

-- set selection tool filters
for entity_type, type_data in pairs(constants.entity_type_data) do
  local blacklist = type_data.blacklist or {}
  for _, entity_data in pairs(data.raw[entity_type]) do
    local entity_name = entity_data.name
    if not blacklist[entity_name] then
      local added = false
      -- electricity
      local energy_source = entity_data.energy_source
      if energy_source and energy_source.type == "electric" then
        added = true
        entities.electricity[#entities.electricity+1] = entity_name
      end
      -- materials
      if type_data.calculators.materials then
        added = true
        entities.materials[#entities.materials+1] = entity_name
      end
      -- all
      if added then
        entities.all[#entities.all+1] = entity_name
      end
    end
  end
end

for measure in pairs(constants.selection_tools) do
  local tool = data.raw["selection-tool"]["rcalc-"..measure.."-selection-tool"]
  tool.entity_filters = entities[measure]
  tool.alt_entity_filters = entities[measure]
end