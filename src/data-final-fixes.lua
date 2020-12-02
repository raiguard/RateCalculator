local table = require("__flib__.table")

local constants = require("constants")

local entities = table.map(constants.measures, function() return {} end)

-- set selection tool filters
for entity_type, type_data in pairs(constants.entity_data) do
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
      if
        type_data.materials_calculator
        or (
          entity_data.energy_source and (
            entity_data.energy_source.type == "burner"
            or entity_data.energy_source.type == "fluid"
          )
        )
      then
        added = true
        entities.materials[#entities.materials+1] = entity_name
      end
      -- pollution
      local emissions_per_second = entity_data.emissions_per_second or 0
      local emissions_per_minute = entity_data.energy_source and entity_data.energy_source.emissions_per_minute or 0
      emissions_per_minute = emissions_per_minute + (emissions_per_second * 60)
      if emissions_per_minute ~= 0 then
        added = true
        entities.pollution[#entities.pollution+1] = entity_name
      end
      -- heat
      if entity_type == "reactor" or entity_data.energy_source and entity_data.energy_source.type == "heat" then
        added = true
        entities.heat[#entities.heat+1] = entity_name
      end
      -- all
      if added then
        entities.all[#entities.all+1] = entity_name
      end
    end
  end
end

for measure in pairs(constants.measures) do
  local tool = data.raw["selection-tool"]["rcalc-"..measure.."-selection-tool"]
  tool.entity_filters = entities[measure]
  tool.alt_entity_filters = entities[measure]
end
