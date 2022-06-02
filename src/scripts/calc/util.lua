local constants = require("constants")

local calc_util = {}

function calc_util.add_rate(tbl, kind, type, name, localised_name, amount, owner, temperature)
  local combined_name = type .. "." .. name
  local override = constants.rate_key_overrides[combined_name]
  if override then
    type = override.type
    name = override.name
    combined_name = override.type .. "." .. override.name
  end
  local data = tbl[combined_name]
  if not data then
    local rate_tbl = {
      type = type,
      name = name,
      temperature = temperature,
      localised_name = localised_name,
      inputs = {
        total_amount = 0,
        total_machines = 0,
      },
      outputs = {
        total_amount = 0,
        total_machines = 0,
      },
    }

    tbl[#tbl + 1] = rate_tbl
    tbl[combined_name] = rate_tbl
    data = tbl[combined_name]
  end
  data = data[kind .. "s"]

  -- Add to totals
  data.total_amount = data.total_amount + amount
  data.total_machines = data.total_machines + 1

  -- Add to owners
  if owner then
    if not data.owners then
      data.owners = {}
    end
    local owner_data = data.owners[owner]
    if not owner_data then
      owner_data = { amount = 0, machines = 0 }
      data.owners[owner] = owner_data
    end
    owner_data.amount = owner_data.amount + amount
    owner_data.machines = owner_data.machines + 1
  end
end

return calc_util
