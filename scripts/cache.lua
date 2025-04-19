local cache = {}

local max_quality_level = -1
for _, quality in pairs(prototypes.quality) do
  log(quality.name .. ": " .. quality.level)
  if quality.level > max_quality_level then
    max_quality_level = quality.level
    cache.highest_quality = quality
  end
end

cache.max_beacon_distance = 0
for _, beacon in pairs(prototypes.get_entity_filtered({ { filter = "type", type = "beacon" } })) do
  cache.max_beacon_distance =
    math.max(cache.max_beacon_distance, beacon.get_supply_area_distance(cache.highest_quality))
end

log("\nRate calculator prototype cache: \n" .. serpent.block(cache))

return cache
