local constants = require("constants")

local calc_util = {}

function calc_util.add_rate(tbl, kind, type, name, localised_name, amount)
  local combined_name = type.."."..name
  local override = constants.rate_key_overrides[combined_name]
  if override then
    type = override[1]
    name = override[2]
    combined_name = override[1].."."..override[2]
  end
  local data = tbl[combined_name]
  if not data then
    local rate_tbl = {
      type = type,
      name = name,
      localised_name = localised_name,
      input_amount = 0,
      input_machines = 0,
      output_amount = 0,
      output_machines = 0
    }

    tbl[#tbl+1] = rate_tbl
    tbl[combined_name] = rate_tbl
    data = tbl[combined_name]
  end
  data[kind.."_amount"] = data[kind.."_amount"] + amount
  data[kind.."_machines"] = data[kind.."_machines"] + 1
end

return calc_util