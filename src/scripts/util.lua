local util = {}

--- Determines if the given stack contains a Rate Calculator tool.
--- @param cursor_stack LuaItemStack
--- @return boolean
function util.is_rcalc_tool(cursor_stack)
  return cursor_stack and cursor_stack.valid_for_read and string.find(cursor_stack.name, "rcalc%-(.+)%-selection%-tool")
end

--- Safely retrieves the selection GUI.
--- @param player_index number
--- @return SelectionGui|nil
function util.get_gui(player_index)
  local player_table = global.players and global.players[player_index]
  if player_table then
    local SelectionGui = player_table.gui
    if SelectionGui and SelectionGui.refs.window.valid then
      return SelectionGui
    end
  end
end

return util
