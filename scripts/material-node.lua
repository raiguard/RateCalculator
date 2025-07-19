local material_node_rate = require("scripts.material-node-rate")

--- Contains the summed output and input rates for a given node.
--- @class MaterialNode
--- @field node Rates.Node
--- @field output MaterialNodeRate
--- @field input MaterialNodeRate
local material_node = {}
local mt = { __index = material_node }
script.register_metatable("material_node", mt)

--- @param node Rates.Node
--- @return MaterialNode
function material_node.new(node)
  local self = {
    node = node,
    output = material_node_rate.new(),
    input = material_node_rate.new(),
  }
  setmetatable(self, mt)
  return self
end

--- @param amount Rates.Configuration.Amount
--- @param config Rates.Configuration
--- @param invert boolean
--- @return boolean empty
function material_node:add(amount, config, invert)
  if amount.amount > 0 then
    self.output:add(amount, config, invert)
  elseif amount.amount < 0 then
    self.input:add(amount, config, invert)
  end

  return self.output:is_empty() and self.input:is_empty()
end

return material_node
