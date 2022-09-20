local util = {}

--- Spawns the given flying text at the cursor and plays an error sound.
--- @param player LuaPlayer
--- @param text LocalisedString
function util.error_flying_text(player, text)
  player.create_local_flying_text({ text = text, create_at_cursor = true })
  player.play_sound({ path = "utility/cannot_build" })
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

--- Determines if the given stack contains a Rate Calculator tool.
--- @param cursor_stack LuaItemStack
--- @return boolean
function util.is_rcalc_tool(cursor_stack)
  return cursor_stack and cursor_stack.valid_for_read and string.find(cursor_stack.name, "rcalc%-(.+)%-selection%-tool")
end

return util
