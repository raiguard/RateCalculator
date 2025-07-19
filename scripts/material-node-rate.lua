local sw = require("__sw-rates-lib__.api-usage")

--- Contains a summed rate and the configurations that contributed to this rate.
--- @class MaterialNodeRate
--- @field amount number
--- @field configurations table<string, {config: Rates.Configuration, amount: uint}>
local material_node_rate = {}
local mt = { __index = material_node_rate }
script.register_metatable("material_node_rate", mt)

--- Creates a new MaterialNodeRate.
--- @return MaterialNodeRate
function material_node_rate.new()
  local self = {
    amount = 0,
    configurations = {},
  }
  setmetatable(self, mt)
  return self
end

--- Adds the given amount and configuration to this MaterialNodeRate. Returns true if the rate is empty and should be deleted.
--- @param amount Rates.Configuration.Amount
--- @param config Rates.Configuration
--- @param invert boolean
--- @return boolean empty
function material_node_rate:add(amount, config, invert)
  local amount_to_sum = amount.amount
  if invert then
    amount_to_sum = amount_to_sum * -1
  end
  self.amount = self.amount + amount_to_sum

  local config_id = sw.configuration.get_id(config)
  local existing_config = self.configurations[config_id]
  if not existing_config then
    existing_config = { config = config, amount = 0 }
    self.configurations[config_id] = existing_config
  end
  existing_config.amount = existing_config.amount + (invert and -1 or 1)
  if existing_config.amount == 0 then
    self.configurations[config_id] = nil
  end

  return not next(self.configurations)
end

--- Returns true if this rate is empty and should be deleted.
--- @return boolean
function material_node_rate:is_empty()
  return not next(self.configurations)
end

return material_node_rate
