local sw = require("__sw-rates-lib__.api-usage")
local material_node = require("scripts.material-node")

--- @class RatesSet
--- @field configurations table<string, RatesNode?>
--- @field id uint
--- @field nodes table<string, MaterialNode?>
local rates_set = {}
local mt = { __index = rates_set }
script.register_metatable("rates_set", mt)

--- Creates a new RatesSet.
--- @return RatesSet
function rates_set.new(id)
  local self = {
    configurations = {},
    id = id,
    nodes = {},
  }
  setmetatable(self, mt)
  return self
end

--- Adds the given configuration to the cache and returns the configuration along with production rates and GUI information.
--- @param config Rates.Configuration
--- @param force LuaForce
--- @param surface LuaSurface
--- @return RatesNode
function rates_set:add_configuration(config, force, surface)
  local config_id = sw.configuration.get_id(config)
  local cached_config = self.configurations[config_id]
  if not cached_config then
    cached_config = {
      config = config,
      production = sw.configuration.get_production(
        config,
        { apply_quality = true, force = force, surface = surface, use_pollution = true }
      ),
      description = sw.configuration.gui_entity(config),
    }
    self.configurations[config_id] = cached_config
  end
  return cached_config
end

--- Adds the rates for the given configuration to the summed rates.
--- @param config RatesNode
--- @param invert boolean
function rates_set:add_rates(config, invert)
  for _, amount in pairs(config.production) do
    local node = amount.node
    local node_id = sw.node.get_id(node)

    local result = self.nodes[node_id]
    if not result then
      result = material_node.new(node)
      self.nodes[node_id] = result
    end

    if result:add(amount, config.config, invert) then
      self.nodes[node_id] = nil
    end
  end
end

--- @return boolean empty
function rates_set:is_empty()
  return not next(self.configurations)
end

--- @param node_id string
--- @return MaterialNode
function rates_set:get_node(node_id)
  local node = self.nodes[node_id]
  if not node then
    error("Node " .. node_id .. " does not exist")
  end
  return node
end

return rates_set
