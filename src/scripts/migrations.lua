return {
  ["1.1.0"] = function()
    -- clean up mistaken `gui_open` key in player tables
    for _, player_table in pairs(global.players) do
      player_table.gui_open = nil
    end
  end
}