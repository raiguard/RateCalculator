local constants = require("constants")

local entity_filters = {}
local alt_entity_filters = {}

-- set selection tool filters
for type, blacklist in pairs(constants.selection_tool_filters) do
  for _, entity_data in pairs(data.raw[type]) do
    local entity_name = entity_data.name
    local is_blacklisted = blacklist[entity_name]
    local energy_source = entity_data.energy_source
    if blacklist.__is_production_machine and not is_blacklisted then
      entity_filters[#entity_filters+1] = entity_name
    end
    if energy_source and energy_source.type == "electric" and not is_blacklisted then
      alt_entity_filters[#alt_entity_filters+1] = entity_name
    end
  end
end
local selection_tool = data.raw["selection-tool"]["rcalc-selection-tool"]
selection_tool.entity_filters = entity_filters
selection_tool.alt_entity_filters = alt_entity_filters