local util = {}

--- @param entity LuaEntity
--- @return LuaEntityPrototype
function util.get_useful_prototype(entity)
  if entity.type == "entity-ghost" then
    -- TODO: [ghosts] Can we ever get a tile here?
    return entity.ghost_prototype --[[@as LuaEntityPrototype]]
  end
  return entity.prototype
end

--- @param entity LuaEntity
--- @return string
function util.get_useful_type(entity)
  if entity.type == "entity-ghost" then
    return entity.ghost_type
  end
  return entity.type
end

--- @param entity LuaEntity
--- @return string
function util.get_useful_name(entity)
  if entity.type == "entity-ghost" then
    return entity.ghost_name
  end
  return entity.name
end

return util
