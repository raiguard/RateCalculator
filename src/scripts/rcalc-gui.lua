local rcalc_gui = {}

local event = require("__flib__.event")
local gui = require("__flib__.gui")

local constants = require("constants")
local fixed_precision_format = require("scripts.fixed-precision-format")

local fixed_format = fixed_precision_format.FormatNumber

local function round(num, num_decimals)
  local mult = 10^(num_decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

gui.add_templates{
  column_label = {type="label", style="bold_label", style_mods={minimal_width=47}},
  icon_column_header = {type="empty-widget", style_mods={left_margin=3, width=32}},
  listbox_with_label = function(name, toolbar_children)
    return {type="flow", style_mods={vertical_spacing=6}, direction="vertical", children={
      {type="label", style="caption_label", style_mods={left_margin=2}, caption={"rcalc-gui."..name}},
      {type="frame", style="rcalc_material_list_box_frame", direction="vertical", save_as="panes."..name..".frame", children={
        {type="frame", style="rcalc_toolbar_frame", save_as="panes."..name..".toolbar", children=toolbar_children},
        {type="scroll-pane", style="rcalc_material_list_box_scroll_pane", save_as="panes."..name..".scroll_pane", children={
          {template="pushers.horizontal"} -- dummy content; setting horizontally_stretchable on the scroll pane itself causes weirdness
        }}
      }}
    }}
  end,
  pushers = {
    horizontal = {type="empty-widget", style_mods={horizontally_stretchable=true}}
  }
}

gui.add_handlers{
  close_button = {
    on_gui_click = function(e)
      rcalc_gui.destroy(game.get_player(e.player_index), global.players[e.player_index])
    end
  },
  window = {
    on_gui_closed = function(e)
      rcalc_gui.destroy(game.get_player(e.player_index), global.players[e.player_index])
    end
  }
}

function rcalc_gui.create(player, player_table, data)
  local gui_data = gui.build(player.gui.screen, {
    {type="frame", style="dialog_frame", direction="vertical", handlers="window", save_as="window", children={
      {type="flow", children={
        {type="label", style="frame_title", caption={"mod-name.RateCalculator"}},
        {type="empty-widget", style="draggable_space", style_mods={horizontally_stretchable=true, height=24, minimal_width=32, right_margin=6, left_margin=6},
          save_as="titlebar.drag_handle"},
        {type="sprite-button", style="close_button", style_mods={width=20, height=20, top_margin=2}, sprite="utility/close_white",
          hovered_sprite="utility/close_black", clicked_sprite="utility/close_black", mouse_button_filter={"left"}, handlers="close_button",
          save_as="titlebar.close_button"}
      }},
      {type="frame", style="window_content_frame_packed", direction="vertical", children={
        {type="frame", style="subheader_frame", children={
          {type="label", style="subheader_caption_label", style_mods={right_margin=4}, caption={"rcalc-gui.units"}},
          {template="pushers.horizontal"},
          {type="flow", style_mods={margin=0, padding=0}, save_as="toolbar.elem_button_flow", children={
            -- TODO generate dynamically with choose-elem-filters
            -- {type="choose-elem-button", style="CGUI_filter_slot_button", style_mods={width=30, height=30}, elem_type="signal"},
          }},
          {type="drop-down", items=constants.units_list, selected_index=2, save_as="toolbar.units_drop_down"}
        }},
        {type="flow", style_mods={padding=12, top_padding=5, horizontal_spacing=12}, children={
          gui.templates.listbox_with_label("ingredients", {
            {template="icon_column_header"},
            {template="column_label", caption={"rcalc-gui.rate"}, tooltip={"rcalc-gui.consumption-rate-description"}},
            {template="pushers.horizontal"}
          }),
          gui.templates.listbox_with_label("products", {
            {template="icon_column_header"},
            {template="column_label", caption={"rcalc-gui.rate"}, tooltip={"rcalc-gui.production-rate-description"}},
            {template="column_label", caption={"rcalc-gui.per-machine"}, tooltip={"rcalc-gui.per-machine-description"}},
            {template="column_label", caption={"rcalc-gui.net-rate"}, tooltip={"rcalc-gui.net-rate-description"}},
            {template="column_label", caption={"rcalc-gui.net-machines"}, tooltip={"rcalc-gui.net-machines-description"}},
            {template="pushers.horizontal"}
          })
        }}
      }}
    }}
  })

  gui_data.titlebar.drag_handle.drag_target = gui_data.window
  gui_data.window.force_auto_center()

  gui_data.data = data
  player_table.gui = gui_data

  player.opened = gui_data.window

  player_table.flags.gui_open = true

  rcalc_gui.update_contents(player, player_table)
end

function rcalc_gui.destroy(player, player_table)
  gui.remove_player_filters(player.index)
  player_table.gui.window.destroy()
  player_table.gui = nil

  player_table.flags.gui_open = false
end

function rcalc_gui.update_contents(player, player_table)
  local gui_data = player_table.gui
  local data = gui_data.data

  for _, category in ipairs{"ingredients", "products"} do
    local scroll_pane = gui_data.panes[category].scroll_pane
    -- scroll_pane.clear()
    for key, material_data in pairs(data[category]) do
      if key ~= "__size" then
        local material_type = material_data.type
        local material_name = material_data.name
        local per_machine_fixed, net_rate_fixed, net_machines_fixed = "------", "------", "------"
        local icon_tt, per_machine_tt, net_rate_tt, net_machines_tt

        if category == "ingredients" then
          icon_tt = material_data.localised_name
        else
          icon_tt = {"", material_data.localised_name, "\n", {"rcalc-gui.n-machines", material_data.machines}}
          local per_crafter = material_data.amount / material_data.machines
          per_machine_fixed = fixed_format(per_crafter, 4 - (per_crafter < 0 and 1 or 0), "2")
          per_machine_tt = round(per_crafter, 3)

          local material_input = data.ingredients[key]
          if material_input then
            local net_rate = material_data.amount - material_input.amount
            net_rate_fixed = fixed_format(net_rate, 4 - (net_rate < 0 and 1 or 0), "2")
            net_rate_tt = round(net_rate, 3)

            local net_machines = net_rate / per_crafter
            net_machines_fixed = fixed_format(net_machines, 4, "2")
            net_machines_tt = round(net_machines, 3)
          end
        end

        gui.build(scroll_pane, {
          {type="frame", style="rcalc_material_info_frame", children={
            {type="sprite-button", style="statistics_slot_button", style_mods={width=32, height=32}, sprite=material_type.."/"..material_name,
              number=material_data.machines, tooltip=icon_tt},
            {type="label", style="rcalc_amount_label", caption=fixed_format(material_data.amount, 4, "2"), tooltip=round(material_data.amount, 3)},
            {type="condition", condition=(category=="products"), children={
              {type="label", style="rcalc_amount_label", style_mods={width=75}, caption=per_machine_fixed, tooltip=per_machine_tt},
              {type="label", style="rcalc_amount_label", style_mods={width=49}, caption=net_rate_fixed, tooltip=net_rate_tt},
              {type="label", style="rcalc_amount_label", style_mods={width=72}, caption=net_machines_fixed, tooltip=net_machines_tt},
            }},
            {type="empty-widget", style_mods={horizontally_stretchable=true, left_margin=-12}}
          }}
        })
      end
    end
  end
end

return rcalc_gui

--[[

-- custom create_from_center function, omitting ensure_xy and using the radius instead of the width
local function create_from_center(position, radius)
  return {
    left_top = {x=position.x-radius, y=position.y-radius},
    right_bottom = {x=position.x+radius, y=position.y+radius}
  }
end

-- custom collides function, omitting ensure_xy since those are already gauranteed
local function collides_with(box1, box2)
  return box1.left_top.x < box2.right_bottom.x and
    box2.left_top.x < box1.right_bottom.x and
    box1.left_top.y < box2.right_bottom.y and
    box2.left_top.y < box1.right_bottom.y
end

]]