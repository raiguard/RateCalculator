local flib_format = require("__flib__/format")
local flib_math = require("__flib__/math")
local flib_gui = require("__flib__/gui-lite")

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
    { type = "label", style = "caption_label", caption = { "gui.rcalc-header-" .. name } },
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
            type = "choose-elem-button",
            style = "rcalc_units_choose_elem_button",
            elem_type = "entity",
            elem_filters = {
              { filter = "type", type = "container" },
              { filter = "type", type = "logistic-container" },
              { filter = "type", type = "cargo-wagon" },
              { filter = "type", type = "storage-tank" },
              { filter = "type", type = "fluid-wagon" },
            },
            tooltip = { "gui.rcalc-capacity-divisor-description" },
          },
          {
            type = "drop-down",
            items = { "Per second", "Per minute", "Per hour", "Transport belts", "Inserters" },
            selected_index = 2,
          },
          { type = "label", caption = "[img=quantity-multiplier]" },
          {
            type = "textfield",
            style = "short_number_textfield",
            style_mods = { width = 40, horizontal_align = "center" },
            tooltip = { "gui.rcalc-manual-multiplier-description" },
            text = "1",
          },
        },
        {
          type = "flow",
          style_mods = { padding = 12, top_padding = 8 },
          direction = "vertical",
          table_with_label("products"),
          table_with_label("ingredients"),
          table_with_label("intermediates"),
        },
      },
    },
  })

  player.opened = elems.rcalc_window

  for path, rates in pairs(set.rates) do
    local prototype = game[rates.type .. "_prototypes"][rates.name]
    local table, style, amount, tooltip
    if rates.output == 0 and rates.input > 0 then
      table = elems.ingredients
      style = "flib_slot_button_default"
      amount = rates.input
      tooltip = {
        "gui.rcalc-slot-description",
        prototype.localised_name,
        flib_format.number(flib_math.round(amount * 60, 0.01)),
        "m",
        flib_format.number(rates.input_machines, true),
        flib_format.number(amount * 60 / rates.input_machines, true),
      }
    elseif rates.output > 0 and rates.input == 0 then
      table = elems.products
      style = "flib_slot_button_default"
      amount = rates.output
      tooltip = {
        "gui.rcalc-slot-description",
        prototype.localised_name,
        flib_format.number(flib_math.round(amount * 60, 0.01)),
        "m",
        flib_format.number(rates.output_machines, true),
        flib_format.number(amount * 60 / rates.output_machines, true),
      }
    else
      table = elems.intermediates
      amount = rates.output - rates.input
      style = "flib_slot_button_default"
      local net_machines_label
      if amount < 0 then
        style = "flib_slot_button_red"
        net_machines_label = { "gui.rcalc-machines-defecit" }
      else
        style = "flib_slot_button_green"
        net_machines_label = { "gui.rcalc-machines-surplus" }
      end
      tooltip = {
        "gui.rcalc-net-slot-description",
        prototype.localised_name,
        -- Net
        flib_format.number(flib_math.round(amount * 60, 0.01)),
        "m",
        -- Output
        flib_format.number(flib_math.round(rates.output * 60, 0.01)),
        flib_format.number(rates.output_machines, true),
        flib_format.number(rates.output * 60 / rates.output_machines, true),
        -- Input
        flib_format.number(flib_math.round(rates.input * 60, 0.01)),
        flib_format.number(rates.input_machines, true),
        flib_format.number(rates.input * 60 / rates.input_machines, true),
        -- Net machines
        net_machines_label,
        flib_format.number(
          flib_math.round(math.abs((amount * 60) / (rates.output * 60) / rates.output_machines), 0.01)
        ),
      }
    end
    flib_gui.add(table, {
      type = "sprite-button",
      name = path,
      style = style,
      sprite = path,
      number = flib_math.round(amount * 60, 0.1),
      tooltip = tooltip,
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
