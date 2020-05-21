local constants = require("constants")

local entity_filters = {}
local i = 0

-- set selection tool filters
for type, blacklist in pairs(constants.selection_tool_filters) do
  for _, entity_data in pairs(data.raw[type]) do
    local entity_name = entity_data.name
    if not blacklist[entity_name] then
      i = i + 1
      entity_filters[i] = entity_name
    end
  end
end
local selection_tool = data.raw["selection-tool"]["rcalc-selection-tool"]
selection_tool.entity_filters = entity_filters
selection_tool.alt_entity_filters = entity_filters