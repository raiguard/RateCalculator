local styles = data.raw["gui-style"].default

local row_height = 45

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

-- FRAME STYLES

styles.rcalc_rates_list_box_frame = {
  type = "frame_style",
  parent = "deep_frame_in_shallow_frame",
  height = (row_height * 8) + 36
}

styles.rcalc_rates_list_box_row_frame = {
  type = "frame_style",
  parent = "statistics_table_item_frame",
  top_padding = 2,
  bottom_padding = 2,
  height = row_height,
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

-- LABEL STYLES

styles.rcalc_amount_label = {
  type = "label_style",
  horizontal_align = "center",
  minimal_width = 80
}

styles.rcalc_info_label = {
  type = "label_style",
  parent = "info_label",
  left_padding = 8,
  bottom_padding = 1
}

styles.rcalc_column_label = {
  type = "label_style",
  parent = "bold_label",
  horizontal_align = "center",
  minimal_width = 80
}

-- SCROLL PANE STYLES

styles.rcalc_rates_list_box_scroll_pane = {
  type = "scroll_pane_style",
  extra_padding_when_activated = 0,
  padding = 0,
  horizontally_stretchable = "on",
  vertically_stretchable = "on",
  graphical_set = {
    shadow = default_inner_shadow
  },
  background_graphical_set = {
    position = {282, 17},
    corner_size = 8,
    overall_tiling_horizontal_padding = 6,
    overall_tiling_vertical_padding = 6,
    overall_tiling_vertical_size = (row_height - 12),
    overall_tiling_vertical_spacing = 12
  },
  vertical_flow_style = {
    type = "vertical_flow_style",
    vertical_spacing = 0
  }
}
