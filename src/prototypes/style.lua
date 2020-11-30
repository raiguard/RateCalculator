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
