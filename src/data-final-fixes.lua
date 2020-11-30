local table = require("__flib__.table")

local constants = require("constants")

local entities = table.map(constants.selection_tools, function() return {} end)

-- set selection tool filters
for type, blacklist in pairs(constants.selection_tool_filters) do
  for _, entity_data in pairs(data.raw[type]) do
    local entity_name = entity_data.name
    if not blacklist[entity_name] then
      local added = false
      local energy_source = entity_data.energy_source
      if blacklist.__produces_consumes_materials then
        added = true
        entities.materials[#entities.materials+1] = entity_name
      end
      if energy_source and energy_source.type == "electric" then
        added = true
        entities.electricity[#entities.electricity+1] = entity_name
      end

      if added then
        entities.all[#entities.all+1] = entity_name
      end
    end
  end
end

for mode in pairs(constants.selection_tools) do
  local tool = data.raw["selection-tool"]["rcalc-"..mode.."-selection-tool"]
  tool.entity_filters = entities[mode]
  tool.alt_entity_filters = entities[mode]
end