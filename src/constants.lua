local constants = {}

local crafter_types = {
  "assembling-machine",
  "furnace",
  "rocket-silo"
}

local crafter_type_lookup = {}

for i = 1, #crafter_types do
  crafter_type_lookup[crafter_types[i]] = true
end

constants.crafter_types = crafter_types
constants.crafter_type_lookup = crafter_type_lookup

return constants