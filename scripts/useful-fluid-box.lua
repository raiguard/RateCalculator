local util = require("scripts.util")

--- @class UsefulFluidBox
--- @field box LuaFluidBox?
--- @field prototypes LuaFluidBoxPrototype[]
local useful_fluid_box = {}
local mt = { __index = useful_fluid_box }
script.register_metatable("useful_fluid_box", mt)

--- @param entity LuaEntity
function useful_fluid_box.new(entity)
  local prototype = util.get_useful_prototype(entity)
  return setmetatable({
    box = entity.type ~= "entity-ghost" and entity.fluidbox or nil,
    prototypes = prototype.fluidbox_prototypes,
  }, mt)
end

--- @param index uint
--- @return Fluid?
function useful_fluid_box:get_fluid(index)
  if self.box then
    return self.box[index]
  end
end

--- @param index uint
--- @return LuaFluidPrototype?
function useful_fluid_box:get_fluid_prototype(index)
  if self.box then
    local filter = self.box.get_filter(index)
    if filter then
      return prototypes.fluid[filter.name]
    end
    local fluid = self.box[index]
    if fluid then
      return prototypes.fluid[fluid.name]
    end
  end

  return self.prototypes[index].filter
end

--- @param index uint
--- @return double?
function useful_fluid_box:get_minimum_temperature(index)
  return self.prototypes[index].minimum_temperature
end

function useful_fluid_box:len()
  if self.box then
    return #self.box
  end
  return #self.prototypes
end

return useful_fluid_box
