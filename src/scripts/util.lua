local util = {}

--- Determines if the given stack contains a Rate Calculator tool.
--- @param cursor_stack LuaItemStack
--- @return boolean
function util.is_rcalc_tool(cursor_stack)
  return cursor_stack and cursor_stack.valid_for_read and string.find(cursor_stack.name, "rcalc%-(.+)%-selection%-tool")
end

return util
