local flib_format = require("__flib__/format")
local flib_gui = require("__flib__/gui-lite")

local colors = {
  input = { r = 1, g = 0.6, b = 0.6 },
  output = { r = 0.6, g = 1, b = 0.6 },
  white = { r = 1, g = 1, b = 1 },
}

local handlers = {}
handlers = {
  close = function(e)
    local player = game.get_player(e.player_index)
    if not player then
      return
    end

    local window = player.gui.screen.rcalc_window
    if window then
      window.destroy()
    end
  end,
}

flib_gui.add_handlers(handlers)

local gui = {}

--- @param player LuaPlayer
--- @param set CalculationSet
function gui.show(player, set)
  local screen = player.gui.screen
  if screen.rcalc_window then
    screen.rcalc_window.destroy()
  end

  local elems = flib_gui.add(screen, {
    {
      type = "frame",
      name = "rcalc_window",
      direction = "vertical",
      elem_mods = { auto_center = true },
      handler = { [defines.events.on_gui_closed] = handlers.close },
      {
        type = "flow",
        drag_target = "rcalc_window",
        {
          type = "label",
          style = "frame_title",
          caption = { "mod-name.RateCalculator" },
          ignored_by_interaction = true,
        },
        { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
        {
          type = "sprite-button",
          style = "frame_action_button",
          sprite = "utility/close_white",
          hovered_sprite = "utility/close_black",
          clicked_sprite = "utility/close_black",
          handler = { [defines.events.on_gui_click] = handlers.close },
        },
      },
      {
        type = "frame",
        name = "scroll_pane",
        style = "inside_deep_frame",
        direction = "vertical",
        {
          type = "frame",
          style = "rcalc_subheader_frame",
          { type = "empty-widget", style_mods = { width = 32 } },
          {
            type = "label",
            style = "caption_label",
            style_mods = { width = 50, horizontal_align = "center" },
            caption = "Output",
          },
          {
            type = "label",
            style = "caption_label",
            style_mods = { width = 50, horizontal_align = "center" },
            caption = "Input",
          },
          {
            type = "label",
            style = "caption_label",
            style_mods = { width = 50, horizontal_align = "center" },
            caption = "Net",
          },
        },
        { type = "scroll-pane", name = "scroll_pane", style = "rcalc_rates_list_box_scroll_pane" },
      },
    },
  })

  player.opened = elems.rcalc_window

  local scroll_pane = elems.scroll_pane

  local i = 0
  for path, rates in pairs(set) do
    local prototype = game[rates.type .. "_prototypes"][rates.name]
    i = i + 1
    local net = rates.output - rates.input
    local net_color = colors.white
    if net > 0 then
      net_color = colors.output
    elseif net < 0 then
      net_color = colors.input
    end
    flib_gui.add(scroll_pane, {
      type = "frame",
      name = path,
      style = "rcalc_rates_list_box_row_frame_" .. (i % 2 == 0 and "even" or "odd"),
      { type = "sprite-button", style = "transparent_slot", tooltip = prototype.localised_name, sprite = path },
      {
        type = "label",
        style_mods = { width = 50, horizontal_align = "center" },
        caption = flib_format.number(rates.output * 60, true),
      },
      {
        type = "label",
        style_mods = { width = 50, horizontal_align = "center" },
        caption = flib_format.number(rates.input * 60, true),
      },
      {
        type = "label",
        style_mods = { font_color = net_color, width = 50, horizontal_align = "center" },
        caption = flib_format.number(net * 60, true),
      },
    })
  end
end

return gui
