local material_node = require("scripts.material-node")
local sw = require("__sw-rates-lib__.api-usage")

--- @class RatesSet
--- @field configurations table<string, CachedConfig>
--- @field lookup table<string, MaterialNode>
local rates_set = {}
local mt = { __index = rates_set }
script.register_metatable("rates_set", mt)

--- Creates a new RatesSet.
--- @return RatesSet
function rates_set.new()
  local self = {
    configurations = {},
    lookup = {},
  }
  setmetatable(self, mt)
  return self
end

--- Adds the given configuration to the cache and returns the configuration along with production rates and GUI information.
--- @param config Rates.Configuration
--- @param force LuaForce
--- @param surface LuaSurface
--- @return CachedConfig
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
--- @param config CachedConfig
--- @param invert boolean
function rates_set:add_rates(config, invert)
  for _, amount in pairs(config.production) do
    local node = amount.node
    local node_id = sw.node.get_id(node)

    local result = self.lookup[node_id]
    if not result then
      result = material_node.new(node)
      self.lookup[node_id] = result
    end

    if result:add(amount, config.config, invert) then
      self.lookup[node_id] = nil
    end
  end
end

--- @return boolean empty
function rates_set:is_empty()
  return not next(self.configurations) -- TODO: Check lookup as well?
end

return rates_set
