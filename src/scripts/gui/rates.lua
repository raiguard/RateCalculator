local gui = require("__flib__.gui-beta")

local rates_gui = {}

local function frame_action_button(sprite, action)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite.."_white",
    hovered_sprite = sprite.."_black",
    clicked_sprite = sprite.."_black",
    mouse_button_filter = {"left"},
    actions = {
      on_click = action
    }
  }
end

function rates_gui.build(player, player_table)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      visible = false,
      ref = {"window"},
      actions = {
        on_closed = {gui = "rates", action = "close"}
      },
      children = {
        {type = "flow", ref = {"titlebar_flow"}, children = {
          {type = "label", style = "frame_title", caption = {"mod-name.RateCalculator"}, ignored_by_interaction = true},
          {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
          frame_action_button("rc_pin", {gui = "rates", action = "toggle_pinned"}),
          frame_action_button("utility/close", {gui = "rates", action = "close"})
        }},
        {type = "frame", style = "inside_shallow_frame", direction = "vertical", children = {
          {type = "label", caption = "Foo"}
        }}
      }
    }
  })

  refs.titlebar_flow.drag_target = refs.window
  refs.window.force_auto_center()

  player_table.guis.rates = {
    refs = refs,
    state = {
      visible = false
    }
  }
end

function rates_gui.destroy(player_table)
  player_table.gui.rates.refs.window.destroy()
  player_table.gui.rates = nil
end

function rates_gui.handle_action(e, msg)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.guis.rates
  local refs = gui_data.refs
  local state = gui_data.state

  local action = msg.action
  if action == "open" then
    state.visible = true
    refs.window.visible = true

    player.opened = refs.window
  elseif action == "close" then
    state.visible = false
    refs.window.visible = false

    if player.opened == refs.window then
      player.opened = nil
    end
  end
end

return rates_gui