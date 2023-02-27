local flib_format = require("__flib__/format")
local flib_math = require("__flib__/math")
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

--- @param name string
--- @return GuiElemDef
local function table_with_label(name)
  return {
    type = "flow",
    direction = "vertical",
    { type = "label", style = "caption_label", caption = name },
    {
      type = "frame",
      style = "slot_button_deep_frame",
      {
        type = "table",
        name = name,
        style = "slot_table",
        style_mods = { minimal_width = 40 * 10, minimal_height = 40 },
        column_count = 10,
      },
    },
  }
end

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
        style = "inside_shallow_frame",
        direction = "vertical",
        {
          type = "frame",
          style = "subheader_frame",
          { type = "label", style = "subheader_caption_label", caption = "Measure:" },
          { type = "empty-widget", style = "flib_horizontal_pusher" },
          {
            type = "drop-down",
            items = { "Per second", "Per minute", "Per hour", "Transport belts", "Inserters" },
            selected_index = 2,
          },
        },
        {
          type = "flow",
          style_mods = { padding = 12 },
          direction = "vertical",
          table_with_label("products"),
          table_with_label("ingredients"),
          table_with_label("intermediates"),
        },
      },
    },
  })

  player.opened = elems.rcalc_window

  for path, rates in pairs(set) do
    local table, style, amount
    if rates.output == 0 and rates.input > 0 then
      table = elems.ingredients
      style = "flib_slot_button_default"
      amount = rates.input
    elseif rates.output > 0 and rates.input == 0 then
      table = elems.products
      style = "flib_slot_button_default"
      amount = rates.output
    else
      table = elems.intermediates
      amount = rates.output - rates.input
      style = "flib_slot_button_default"
      if amount > 0 then
        style = "flib_slot_button_green"
      elseif amount < 0 then
        style = "flib_slot_button_red"
      end
    end
    local prototype = game[rates.type .. "_prototypes"][rates.name]
    flib_gui.add(table, {
      type = "sprite-button",
      name = path,
      style = style,
      sprite = path,
      number = flib_math.round(amount * 60, 0.1),
      tooltip = { "", prototype.localised_name, "\n", flib_format.number(flib_math.round(amount * 60, 0.01)) },
    })
  end

  for _, table in pairs({ elems.ingredients, elems.products, elems.intermediates }) do
    if next(table.children) then
      table.parent.parent.visible = true
    else
      table.parent.parent.visible = false
    end
  end
end

return gui
