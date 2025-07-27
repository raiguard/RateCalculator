local flib_table = require("__flib__.table")

local rates_set = require("scripts.rates-set")

--- Manages RatesSets.
--- @class RatesSetManager
--- @field next_set_id uint
--- @field sets table<uint, RatesSet?>
--- @field player_sets table<uint, {active_index: uint, ids: uint[]}>
local rates_set_manager = {}
local mt = { __index = rates_set_manager }
script.register_metatable("rates_set_manager", mt)

--- Creates and returns a new RatesSetManager.
--- @return RatesSetManager
function rates_set_manager.new()
  --- @type RatesSetManager
  local self = {
    next_set_id = 1,
    player_sets = {},
    sets = {},
  }
  setmetatable(self, mt)
  return self
end

--- Creates and returns a new RatesSet.
--- @param player_index uint
--- @return RatesSet
function rates_set_manager:new_set(player_index)
  local id = self.next_set_id
  self.next_set_id = self.next_set_id + 1

  self.sets[id] = rates_set.new(id)

  local player_sets = self.player_sets[player_index]
  if not player_sets then
    player_sets = { active_index = 0, ids = {} }
    self.player_sets[player_index] = player_sets
  end

  table.insert(player_sets.ids, id)
  player_sets.active_index = #player_sets.ids

  return self.sets[id]
end

--- Assets that the given RatesSet exists and returns it.
--- @param id uint
--- @return RatesSet
function rates_set_manager:get_assert(id)
  local set = self.sets[id]
  assert(set, "Set with ID " .. id .. " does not exist.")
  return set
end

--- Gets the active RatesSet for the given player, if any.
--- @param player_index uint
--- @return RatesSet?
function rates_set_manager:get_active(player_index)
  local player_sets = self.player_sets[player_index]
  if not player_sets then
    return
  end
  local id = player_sets.ids[player_sets.active_index]
  if not id then
    return
  end
  return self.sets[id]
end

--- @param set_spec RatesSet|uint
function rates_set_manager:delete_set(set_spec)
  --- @type uint
  local id
  if type(set_spec) == "number" then
    id = set_spec
  else
    id = set_spec.id
  end

  assert(self.sets[id], "Attempted to delete set " .. id .. " when it did not exist.")
  self.sets[id] = nil

  -- TODO: Keep a list of players on each set so that we don't have to do it this way
  for _, player_sets in pairs(self.player_sets) do
    local index = flib_table.find(player_sets, id)
    if index then
      table.remove(player_sets, index)
      if player_sets.active_index >= index then
        player_sets.active_index = player_sets.active_index - 1
      end
    end
  end
end

return rates_set_manager
