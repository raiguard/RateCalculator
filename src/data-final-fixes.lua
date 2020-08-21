local constants = require("constants")

local entity_filters = {}
local i = 0

-- set selection tool filters
for type, blacklist in pairs(constants.selection_tool_filters) do
  for _, entity_data in pairs(data.raw[type]) do
    local entity_name = entity_data.name
    local energy_source = entity_data.energy_source
    if blacklist.__ignore_energy_type or (energy_source and energy_source.type == "electric") then
      if not blacklist[entity_name] then
        i = i + 1
        entity_filters[i] = entity_name
      end
    end
  end
end
local selection_tool = data.raw["selection-tool"]["rcalc-selection-tool"]
selection_tool.entity_filters = entity_filters
selection_tool.alt_entity_filters = entity_filters