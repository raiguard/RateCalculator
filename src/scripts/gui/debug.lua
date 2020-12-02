local gui = require("__flib__.gui-beta")

local fixed_format = require("lib.fixed-precision-format")

local debug_gui = {}

function debug_gui.build(player, player_table)
  local children = {}
  for measure, rates_parent in pairs(player_table.selection) do
    for rate_type, rates in pairs(rates_parent) do
      if table_size(rates) > 0 then
        local table_children = {
          {type = "label", style = "bold_label", caption = "Name"},
          {type = "label", style = "bold_label", caption = "Machines"},
          {type = "label", style = "bold_label", caption = "Amount"},
        }
        for _, data in pairs(rates) do
          table_children[#table_children+1] = {
            type = "label",
            style = "label",
            caption = data.localised_name
          }
          table_children[#table_children+1] = {
            type = "label",
            caption = data.machines
          }
          table_children[#table_children+1] = {
            type = "label",
            caption = fixed_format(data.amount * 60, 4 - ((data.amount * 60) < 0 and 1 or 0), "2"),
          }
        end
        children[#children+1] = {
          type = "label",
          style = "caption_label",
          caption = measure.." "..rate_type
        }
        children[#children + 1] = {
          type = "table",
          style = "bordered_table",
          column_count = 3,
          children = table_children
        }
      end
    end
  end

  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      caption = "DEBUG",
      ref = {"window"},
      actions = {
        on_closed = {gui = "debug", action = "close"}
      },
      children = {
        {type = "frame", style = "inside_shallow_frame", children = {
          {
            type = "scroll-pane",
            style = "flib_naked_scroll_pane",
            style_mods = {maximal_height = 600},
            ref = {"scroll"},
            children = children
          }
        }}
      }
    }
  })

  refs.window.force_auto_center()
  player.opened = refs.window

  player_table.guis.debug = refs
end

function debug_gui.destroy(player_table)
  player_table.guis.debug.window.destroy()
  player_table.guis.debug = nil
end

function debug_gui.handle_action(e, msg)
  if msg.action == "close" then
    local player_table = global.players[e.player_index]
    debug_gui.destroy(player_table)
  end
end

return debug_gui