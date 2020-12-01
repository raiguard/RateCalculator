return {
  ["1.1.0"] = function()
    -- clean up mistaken `gui_open` key in player tables
    for _, player_table in pairs(global.players) do
      player_table.gui_open = nil
    end
  end,
  ["1.1.5"] = function()
    -- the format was changed
    global.players_to_iterate = {}
  end,
  ["1.3.0"] = function()
    -- remove old GUI data from global
    for _, player_table in pairs(global.players) do
      local gui_data = player_table.gui
      if gui_data then
        gui_data.window.destroy()
        player_table.gui = nil
      end
      player_table.guis = {}
      player_table.last_tool_measure = "all"
    end
  end
}