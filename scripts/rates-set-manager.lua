local flib_table = require("__flib__.table")

--- Manages RatesSets.
--- @class RatesSetManager
--- @field next_set_id uint
--- @field sets table<uint, RatesSet?>
--- @field player_sets table<uint, {active_index: uint, ids: uint[]}>
local rates_set_manager = {}
local mt = { __index = rates_set_manager }
script.register_metatable("rates_set_manager", mt)

--- Returns a new PlayerSets.
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

--- Adds the given RatesSet to this PlayerSets.
--- @param set RatesSet
--- @param player_index uint?
function rates_set_manager:add(set, player_index)
  local id = self.next_set_id
  self.next_set_id = self.next_set_id + 1

  self.sets[id] = set

  if not player_index then
    return
  end

  local player_sets = self.player_sets[player_index]
  if not player_sets then
    player_sets = { active_index = 0, ids = {} }
    self.player_sets[player_index] = player_sets
  end

  table.insert(player_sets.ids, id)
  player_sets.active_index = #player_sets.ids
end

--- Gets the given RatesSet, if it exists.
--- @param id uint
--- @return RatesSet?
function rates_set_manager:get(id)
  return self.sets[id]
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

return rates_set_manager
