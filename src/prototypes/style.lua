local constants = require("constants")

local styles = data.raw["gui-style"].default

-- BUTTON STYLES

styles.rcalc_material_icon_button = {
  type = "button_style",
  parent = "flib_standalone_slot_button_default",
  height = 32,
  width = 32
}

styles.rcalc_units_choose_elem_button = {
  type = "button_style",
  parent = "slot_button",
  height = 30,
  width = 30
}

styles.rcalc_row_button = {
  type = "button_style",
  parent = "flib_standalone_slot_button_default",
  size = 32
}

-- FLOW STYLES

styles.rcalc_stacked_labels_flow = {
  type = "vertical_flow_style",
  horizontal_align = "center",
  vertical_align = "center",
  vertical_spacing = -4,
  top_margin = -1,
  bottom_margin = -2
}

styles.rcalc_totals_labels_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 8
}

-- FRAME STYLES

styles.rcalc_rates_list_box_frame = {
  type = "frame_style",
  parent = "deep_frame_in_shallow_frame"
}

styles.rcalc_rates_list_box_row_frame = {
  type = "frame_style",
  parent = "statistics_table_item_frame",
  top_padding = 2,
  bottom_padding = 2,
  height = constants.row_height,
  horizontally_stretchable = "on",
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
  -- right_padding = 8,
  horizontal_flow_style = {
    type = "horizontal_flow_style",
    horizontal_spacing = 12,
    vertical_align = "center"
  }
}

styles.rcalc_totals_frame = {
  type = "frame_style",
  parent = "subfooter_frame",
  top_padding = 4,
  left_padding = 12,
  right_padding = 12,
  bottom_padding = 2,
  height = 36
}

styles.rcalc_multiplier_frame = {
  type = "frame_style",
  parent = "subfooter_frame",
  top_padding = 2,
  bottom_padding = 2,
  height = 36
}

-- LABEL STYLES

local min_column_width = 60

styles.rcalc_amount_label = {
  type = "label_style",
  horizontal_align = "center",
  minimal_width = min_column_width
}

styles.rcalc_column_label = {
  type = "label_style",
  parent = "bold_label",
  horizontal_align = "center",
  minimal_width = min_column_width
}

-- SCROLL PANE STYLES

styles.rcalc_rates_list_box_scroll_pane = {
  type = "scroll_pane_style",
  extra_padding_when_activated = 0,
  padding = 0,
  horizontally_stretchable = "on",
  minimal_height = 45,
  maximal_height = 45 * 9,
  graphical_set = {
    shadow = default_inner_shadow
  },
  background_graphical_set = {
    position = {282, 17},
    corner_size = 8,
    overall_tiling_horizontal_padding = 6,
    overall_tiling_vertical_padding = 6,
    overall_tiling_vertical_size = (constants.row_height - 12),
    overall_tiling_vertical_spacing = 12
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 0
  }
}

-- SLIDER STYLES

styles.rcalc_multiplier_slider = {
  type = "slider_style",
  horizontally_stretchable = "on",
  left_margin = 12,
  right_margin = 12,
  top_margin = 7
}

-- TEXTFIELD STYLES

styles.rcalc_multiplier_textfield = {
  type = "textbox_style",
  top_margin = -2,
  horizontal_align = "center",
  width = 80
}

styles.rcalc_invalid_multiplier_textfield = {
  type = "textbox_style",
  parent = "invalid_value_textfield",
  top_margin = -2,
  horizontal_align = "center",
  width = 80
}
