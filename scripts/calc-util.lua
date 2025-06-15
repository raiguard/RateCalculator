--- @alias RateCategory
--- | "output"
--- | "input"

--- @class ResourceData
--- @field occurrences uint
--- @field products Product[]
--- @field required_fluid Product?
--- @field mining_time double

--- @alias Timescale
--- | "per-second",
--- | "per-minute",
--- | "per-hour",
--- | "transport-belts",
--- | "inserters",

--- @class CalcUtil
local calc_util = {}

--- @param set CalculationSet
--- @param error CalculationError
function calc_util.add_error(set, error)
  set.errors[error] = true
end

--- @param set CalculationSet
--- @param category RateCategory
--- @param type string
--- @param name string
--- @param quality string
--- @param amount double
--- @param invert boolean
--- @param machine_id string? "name/quality"
--- @param temperature double?
function calc_util.add_rate(set, category, type, name, quality, amount, invert, machine_id, temperature)
  if math.abs(amount) < 0.0000001 then
    return
  end
  local set_rates = set.rates
  local path = type .. "/" .. name .. "/" .. quality .. (temperature or "")
  local rates = set_rates[path]
  if not rates then
    if invert then
      return -- Don't remove from rates that don't exist.
    end
    --- @type Rates
    rates = {
      type = type,
      name = name,
      quality = quality,
      temperature = temperature,
      output = { machines = 0, machine_counts = {}, rate = 0 },
      input = { machines = 0, machine_counts = {}, rate = 0 },
    }
    set_rates[path] = rates
  end
  if invert then
    amount = -amount
  end
  --- @type Rate
  local rate = rates[category]
  if machine_id then
    local counts = rate.machine_counts
    -- Don't remove a machine that doesn't exist
    if not counts[machine_id] and invert then
      goto no_rate
    end
    counts[machine_id] = (counts[machine_id] or 0) + (invert and -1 or 1)
    if counts[machine_id] == 0 then
      counts[machine_id] = nil
    end
  end
  rate.rate = math.max(rate.rate + amount, 0)
  rate.machines = rate.machines + (invert and -1 or 1)
  -- Account for floating-point imprecision
  if rate.rate < 0.00001 then
    rate.rate = 0
  end

  ::no_rate::
  if rates.input.machines == 0 and rates.output.machines == 0 then
    set_rates[path] = nil
  end
end

return calc_util
