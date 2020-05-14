local constants = require("constants")

local function mipped_icon(name, position, filename, size, mipmap_count, mods)
  local def = {
    type = "sprite",
    name = name,
    filename = filename,
    position = position,
    size = size or 32,
    mipmap_count = mipmap_count or 2,
    flags = {"icon"}
  }
  if mods then
    for k,v in pairs(mods) do
      def[k] = v
    end
  end
  return def
end

local shortcut_sheet = "__RateCalculator__/graphics/shortcut.png"

data:extend{
  -- custom input
  {
    type = "custom-input",
    name = "rcalc-get-selection-tool",
    key_sequence = "ALT + X",
    action = "create-blueprint-item",
    item_to_create = "rcalc-selection-tool"
  },
  -- selection tool
  {
    type = "selection-tool",
    name = "rcalc-selection-tool",
    icons = {
      {icon="__RateCalculator__/graphics/black.png", icon_size=1, scale=64},
      {icon="__RateCalculator__/graphics/selection-tool.png", icon_size=32, mipmap_count=2}
    },
    selection_mode = {"any-entity", "same-force"},
    selection_color = {r=1, g=1, b=0},
    selection_cursor_box_type = "entity",
    entity_type_filters = constants.selection_tool_types,
    alt_selection_mode = {"any-entity", "same-force"},
    alt_selection_color = {r=1, g=0, b=0},
    alt_selection_cursor_box_type = "not-allowed",
    alt_entity_type_filters = constants.selection_tool_types,
    stack_size = 1,
    flags = {"hidden", "only-in-cursor", "not-stackable"}
  },
  -- shortcut
  {
    type = "shortcut",
    name = "rcalc-get-selection-tool",
    icon = mipped_icon(nil, {0,0}, shortcut_sheet, 32, 2),
    disabled_icon = mipped_icon(nil, {48,0}, shortcut_sheet, 32, 2),
    small_icon = mipped_icon(nil, {0,32}, shortcut_sheet, 24, 2),
    disabled_small_icon = mipped_icon(nil, {36,32}, shortcut_sheet, 24, 2),
    action = "create-blueprint-item",
    item_to_create = "rcalc-selection-tool",
    associated_control_input = "rcalc-get-selection-tool"
  }
}

-- -----------------------------------------------------------------------------
-- GUI STYLES

local styles = data.raw["gui-style"].default

-- BUTTON STYLES

styles.rcalc_material_icon_button = {
  type = "button_style",
  parent = "statistics_slot_button",
  height = 32,
  width = 32,
  disabled_graphical_set = styles.statistics_slot_button.default_graphical_set
}

-- FRAME STYLES

styles.rcalc_material_list_box_frame = {
  type = "frame_style",
  parent = "inside_deep_frame",
  height = 300,
  graphical_set = {
    base = {
      position = {85,0},
      corner_size = 8,
      draw_type = "outer",
      center = {position={42,8}, size=1}
    },
    shadow = default_inner_shadow
  }
}

styles.rcalc_material_info_frame = {
  type = "frame_style",
  parent = "statistics_table_item_frame",
  top_padding = 2,
  bottom_padding = 2,
  horizontal_flow_style = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontal_spacing = 12
  }
}

styles.rcalc_toolbar_frame = {
  type = "frame_style",
  parent = "subheader_frame",
  horizontal_flow_style = {
    type = "horizontal_flow_style",
    horizontal_spacing = 12,
    vertical_align = "center"
  }
}

-- LABEL STYLES

styles.rcalc_amount_label = {
  type = "label_style",
  width = 47,
  horizontal_align = "center"
}

-- SCROLL PANE STYLES

styles.rcalc_material_list_box_scroll_pane = {
  type = "scroll_pane_style",
  extra_padding_when_activated = 0,
  padding = 0,
  vertically_stretchable = "on",
  graphical_set = {
    shadow = default_inner_shadow
  },
  background_graphical_set = {
    position = {282, 17},
    corner_size = 8,
    overall_tiling_horizontal_padding = 6,
    overall_tiling_vertical_padding = 6,
    overall_tiling_vertical_size = 32,
    overall_tiling_vertical_spacing = 12
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 0
  }
}