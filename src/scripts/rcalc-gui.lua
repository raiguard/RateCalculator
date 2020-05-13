local rcalc_gui = {}

local event = require("__flib__.event")
local gui = require("__flib__.gui")

local constants = require("constants")

gui.add_templates{
  listbox_with_label = function(name)
    return {type="flow", direction="vertical", children={
      {type="label", style="bold_label", caption={"rcalc-gui."..name}},
      {type="frame", style="rcalc_material_list_box_frame", save_as="panes."..name..".frame", children={
        {type="scroll-pane", style="rcalc_"..name.."_list_box_scroll_pane", save_as="panes."..name..".scroll_pane"}
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
      log(serpent.block(e))
    end
  }
}

function rcalc_gui.create(player, player_table, data)
  local elems = gui.build(player.gui.screen, {
    {type="frame", style="dialog_frame", direction="vertical", save_as="window", children={
      {type="flow", children={
        {type="label", style="frame_title", caption={"mod-name.RateCalculator"}},
        {type="empty-widget", style="draggable_space", style_mods={horizontally_stretchable=true, height=24, minimal_width=32}, save_as="titlebar.drag_handle"},
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
          {type="sprite-button", style="tool_button", sprite="utility/search_icon", tooltip={"gui.search"}, mouse_button_filter={"left"},
            save_as="toolbar.search_button"}
        }},
        {type="flow", style_mods={padding=12, top_padding=8, horizontal_spacing=12}, children={
          gui.templates.listbox_with_label("ingredients"),
          gui.templates.listbox_with_label("products")
        }}
      }}
    }}
  })

  elems.titlebar.drag_handle.drag_target = elems.window
  elems.window.force_auto_center()
end

function rcalc_gui.destroy(player, player_table)
  gui.remove_player_filters(player.index)
end

return rcalc_gui