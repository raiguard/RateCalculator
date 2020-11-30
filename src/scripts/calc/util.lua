local constants = require("constants")

local calc_util = {}

function calc_util.add_rate(tbl, type, name, localised_name, amount)
  local combined_name = type.."."..name
  local override = constants.rate_key_overrides[combined_name]
  if override then
    type = override[1]
    name = override[2]
    combined_name = override[1].."."..override[2]
  end
  local data = tbl[combined_name]
  if data then
    data.amount = data.amount + amount
    data.machines = data.machines + 1
  else
    tbl[combined_name] = {
      type = type,
      name = name,
      localised_name = localised_name,
      amount = amount,
      machines = 1
    }
    tbl.__size = tbl.__size + 1
  end
end

return calc_util