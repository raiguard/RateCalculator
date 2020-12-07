local global_data = require("scripts.global-data")
local player_data = require("scripts.player-data")

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
  ["2.0.0"] = function()
    -- destroy old GUIs
    for _, player_table in pairs(global.players) do
      local gui_data = player_table.gui
      if gui_data then
        gui_data.window.destroy()
      end
    end

    -- NUKE EVERYTHING
    global = {}

    -- re-initialize
    global_data.init()
    for i in pairs(game.players) do
      player_data.init(i)
      -- refresh() will happen after this during generic migrations
    end
  end
}