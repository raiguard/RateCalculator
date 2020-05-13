local rcalc_gui = {}

local event = require("__flib__.event")
local gui = require("__flib__.gui")

local constants = require("constants")
local fixed_precision_format = require("scripts.fixed-precision-format")

local function round(num, num_decimals)
  local mult = 10^(num_decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

gui.add_templates{
  listbox_with_label = function(name, toolbar_children)
    return {type="flow", style_mods={vertical_spacing=6}, direction="vertical", children={
      {type="label", style="caption_label", style_mods={left_margin=2}, caption={"rcalc-gui."..name}},
      {type="frame", style="rcalc_material_list_box_frame", direction="vertical", save_as="panes."..name..".frame", children={
        {type="frame", style="rcalc_toolbar_frame", save_as="panes."..name..".toolbar", children=toolbar_children},
        {type="scroll-pane", style="rcalc_material_list_box_scroll_pane", save_as="panes."..name..".scroll_pane"}
      }}
    }}
  end,
  pushers = {
    horizontal = {type="empty-widget", style_mods={horizontally_stretchable=true}}
  },
  sort_checkbox = {type="checkbox", style="rcalc_sort_checkbox_inactive", state=true}
}

gui.add_handlers{
  close_button = {
    on_gui_click = function(e)
      log(serpent.block(e))
    end
  }
}

function rcalc_gui.create(player, player_table, data)
  local gui_data = gui.build(player.gui.screen, {
    {type="frame", style="dialog_frame", direction="vertical", save_as="window", children={
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
          {type="drop-down", items=constants.units_list, save_as="toolbar.units_drop_down"},
          {type="flow", style_mods={margin=0, padding=0}, save_as="toolbar.elem_button_flow", children={
            -- TODO generate dynamically with choose-elem-filters
            {type="choose-elem-button", style="CGUI_filter_slot_button", style_mods={width=30, height=30}, elem_type="signal"},
          }},
          {template="pushers.horizontal"},
          {type="textfield", mods={visible=false}, save_as="toolbar.search_textfield"},
          {type="sprite-button", style="tool_button", sprite="utility/search_icon", tooltip={"gui.search"}, mouse_button_filter={"left"}, mods={enabled=false},
            save_as="toolbar.search_button"}
        }},
        {type="flow", style_mods={padding=12, top_padding=5, horizontal_spacing=12}, children={
          gui.templates.listbox_with_label("ingredients", {
            {template="sort_checkbox", style_mods={left_margin=4}, caption={"rcalc-gui.name"}},
            {template="sort_checkbox", caption={"rcalc-gui.rate"}},
            {template="pushers.horizontal"}
          }),
          gui.templates.listbox_with_label("products", {
            {template="sort_checkbox", style_mods={left_margin=4}, caption={"rcalc-gui.name"}},
            {template="sort_checkbox", caption={"rcalc-gui.rate"}},
            {template="sort_checkbox", caption={"rcalc-gui.per-crafter"}},
            {template="sort_checkbox", caption={"rcalc-gui.net-rate"}},
            {template="sort_checkbox", caption={"rcalc-gui.net-crafters"}},
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

  -- TODO create bounding box

  rcalc_gui.update_contents(player, player_table)
end

function rcalc_gui.update_contents(player, player_table)
  -- TODO textual search

  local gui_data = player_table.gui
  local data = gui_data.data

  for _, category in ipairs{"ingredients", "products"} do
    local scroll_pane = gui_data.panes[category].scroll_pane
    for key, material_data in pairs(data[category]) do
      if key ~= "__size" then
        local material_type = material_data.type
        local material_name = material_data.name
        gui.build(scroll_pane, {
          {type="frame", style="rcalc_material_info_frame", children={
            {type="flow", style_mods={margin=0, padding=0, width=49, horizontal_align="center"}, children={
              {type="sprite-button", style="statistics_slot_button", style_mods={width=32, height=32}, sprite=material_type.."/"..material_name,
                tooltip={material_type.."-name."..material_name}},
            }},
            {type="label", style="rcalc_amount_label", caption=fixed_precision_format.FormatNumber(material_data.amount, 4, "2"),
              tooltip=round(material_data.amount, 3)},
            {type="empty-widget", style_mods={horizontally_stretchable=true, left_margin=-12}}
          }}
        })
      end
    end
  end
end

function rcalc_gui.destroy(player, player_table)
  gui.remove_player_filters(player.index)
end

return rcalc_gui