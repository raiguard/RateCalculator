local on_tick_n = require("__flib__.on-tick-n")

local global_data = require("scripts.global-data")
local player_data = require("scripts.player-data")

return {
  ["1.1.0"] = function()
    -- Clean up mistaken `gui_open` key in player tables
    for _, player_table in pairs(global.players) do
      player_table.gui_open = nil
    end
  end,
  ["1.1.5"] = function()
    -- The format was changed
    global.players_to_iterate = {}
  end,
  ["2.0.0"] = function()
    -- Destroy old GUIs
    for _, player_table in pairs(global.players) do
      local gui_data = player_table.gui
      if gui_data then
        gui_data.window.destroy()
      end
    end

    -- NUKE EVERYTHING
    global = {}

    -- Re-initialize
    global_data.init()
    for i in pairs(game.players) do
      player_data.init(i)
      -- refresh() will happen after this during generic migrations
    end
  end,
  ["2.3.0"] = function()
    on_tick_n.init()
  end,
  ["2.4.0"] = function()
    -- Destroy old GUI and remove old GUI data
    for _, player_table in pairs(global.players) do
      local gui_data = player_table.guis and player_table.guis.selection
      if gui_data and gui_data.refs.window.valid then
        gui_data.refs.window.destroy()
        player_table.guis = nil
      end
      player_table.selection = nil
    end
  end,
}
