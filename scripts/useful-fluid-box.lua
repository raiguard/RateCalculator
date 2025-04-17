local util = require("scripts.util")

--- Provides an abstraction over an entity's fluid boxes to handle ghost cases.
--- @class UsefulFluidBox
--- @field box LuaFluidBox?
--- @field prototypes LuaFluidBoxPrototype[]
local useful_fluid_box = {}
local mt = { __index = useful_fluid_box }
script.register_metatable("useful_fluid_box", mt)

--- Creates a new UsefulFluidBox.
--- @param entity LuaEntity
function useful_fluid_box.new(entity)
  local prototype = util.get_useful_prototype(entity)
  return setmetatable({
    box = entity.type ~= "entity-ghost" and entity.fluidbox or nil,
    prototypes = prototype.fluidbox_prototypes,
  }, mt)
end

--- Returns the physical fluid within the box, if any.
--- @param index uint
--- @return Fluid?
function useful_fluid_box:get_fluid(index)
  if self.box then
    return self.box[index]
  end
end

--- Returns the fluid prototype matching the fluidbox's filter or the physical fluid contents.
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

--- Returns the minimum temperature of the fluidbox.
--- @param index uint
--- @return double?
function useful_fluid_box:get_minimum_temperature(index)
  return self.prototypes[index].minimum_temperature
end

--- Returns the number of fluid boxes.
--- @return integer
function useful_fluid_box:len()
  if self.box then
    return #self.box
  end
  return #self.prototypes
end

return useful_fluid_box
