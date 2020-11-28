local data_util = require("__flib__.data-util")

local shortcut_sheet = "__RateCalculator__/graphics/shortcut.png"

data:extend{
  -- custom input
  {
    type = "custom-input",
    name = "rcalc-get-selection-tool",
    key_sequence = "ALT + X",
    action = "spawn-item",
    item_to_spawn = "rcalc-selection-tool"
  },
  -- selection tool
  {
    type = "selection-tool",
    name = "rcalc-selection-tool",
    icons = {
      {icon = data_util.black_image, icon_size = 1, scale = 64},
      {icon = "__RateCalculator__/graphics/selection-tool.png", icon_size = 32, mipmap_count = 2}
    },
    selection_mode = {"any-entity", "same-force"},
    selection_color = {r = 1, g = 1, b = 0},
    selection_cursor_box_type = "entity",
    alt_selection_mode = {"any-entity", "same-force"},
    alt_selection_color = {r = 1, g = 1, b = 0},
    alt_selection_cursor_box_type = "entity",
    stack_size = 1,
    flags = {"hidden", "only-in-cursor", "not-stackable", "spawnable"}
  },
  -- shortcut
  {
    type = "shortcut",
    name = "rcalc-get-selection-tool",
    icon = data_util.build_sprite(nil, {0,0}, shortcut_sheet, 32, 2),
    disabled_icon = data_util.build_sprite(nil, {48,0}, shortcut_sheet, 32, 2),
    small_icon = data_util.build_sprite(nil, {0,32}, shortcut_sheet, 24, 2),
    disabled_small_icon = data_util.build_sprite(nil, {36,32}, shortcut_sheet, 24, 2),
    action = "spawn-item",
    item_to_spawn = "rcalc-selection-tool",
    associated_control_input = "rcalc-get-selection-tool"
  }
}

-- -----------------------------------------------------------------------------
-- SPRITES

local frame_action_icons = "__RateCalculator__/graphics/frame-action-icons.png"

data:extend{
  data_util.build_sprite("rc_pin_black", {0, 0}, frame_action_icons, 32),
  data_util.build_sprite("rc_pin_white", {32, 0}, frame_action_icons, 32),
}

-- -----------------------------------------------------------------------------
-- GUI STYLES

local styles = data.raw["gui-style"].default

-- BUTTON STYLES

styles.rcalc_material_icon_button = {
  type = "button_style",
  parent = "flib_standalone_slot_button_default",
  height = 32,
  width = 32
}

styles.rcalc_choose_elem_button = {
  type = "button_style",
  parent = "slot_button",
  height = 30,
  width = 30
}

-- FRAME STYLES

styles.rcalc_material_list_box_frame = {
  type = "frame_style",
  parent = "deep_frame_in_shallow_frame",
  height = 300
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
  left_padding = 8,
  right_padding = 8,
  horizontal_flow_style = {
    type = "horizontal_flow_style",
    horizontal_spacing = 12,
    vertical_align = "center"
  }
}

-- LABEL STYLES

styles.rcalc_amount_label = {
  type = "label_style",
  horizontal_align = "center"
}

styles.rcalc_info_label = {
  type = "label_style",
  parent = "info_label",
  left_padding = 8,
  bottom_padding = 1
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