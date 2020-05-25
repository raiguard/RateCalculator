local util = {}

local table = table

-- the following were borrowed from Therenas's lualib:
-- https://github.com/ClaudeMetz/FactorioUtilLib

-- utility function that removes from a sorted array in place
function util.array_remove(orig_table, value)
  local i = 1
  local found = false
  while i <= #orig_table and not found do
    local curr = orig_table[i]
    if curr >= value then
      found = true
    end
    if curr == value then
      table.remove(orig_table, i)
    end
    i = i+1
  end
end

-- utility function that inserts into a sorted array in place
function util.array_insert(orig_table, value)
  local i = 1
  local found = false
  while i <= #orig_table and not found do
    local curr = orig_table[i]
    if curr >= value then
      found=true
    end
    if curr > value then
      table.insert(orig_table, i, value)
    end
    i = i+1
  end
  if not found then
    table.insert(orig_table, value)
  end
end

return util