local material_node_rate = require("scripts.material-node-rate")

--- @alias MaterialNode.GuiCategory
--- | "ingredient"
--- | "intermediate"
--- | "product"

--- Contains the summed output and input rates for a given node.
--- @class MaterialNode
--- @field node Rates.Node
--- @field output MaterialNodeRate
--- @field input MaterialNodeRate
--- @field private gui_category MaterialNode.GuiCategory?
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

  self.gui_category = nil -- Invalidate cached category

  return self.output:is_empty() and self.input:is_empty()
end

--- @private
--- @return MaterialNode.GuiCategory
function material_node:compute_gui_category()
  local has_output = next(self.output.configurations) ~= nil
  local has_input = next(self.input.configurations) ~= nil
  if has_output and has_input then
    return "intermediate"
  elseif has_output then
    return "product"
  elseif has_input then
    return "ingredient"
  else
    error("Material node has no rates and should not exist!")
  end
end

--- @return MaterialNode.GuiCategory
function material_node:get_gui_category()
  if not self.gui_category then
    self.gui_category = self:compute_gui_category()
  end
  return self.gui_category
end

--- Returns a value that will sort this node based on the net rate.
--- @return number
function material_node:get_sorting_value()
  local category = self:get_gui_category()
  if category == "ingredient" then
    return self.input.amount
  elseif category == "intermediate" then
    return self.output.amount + self.input.amount
  elseif category == "product" then
    return -self.output.amount
  else
    error("Invalid material node category " .. category)
  end
end

return material_node
