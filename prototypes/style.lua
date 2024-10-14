local styles = data.raw["gui-style"].default

styles.rcalc_units_choose_elem_button = {
  type = "button_style",
  parent = "flib_slot_button_default",
  height = 30,
  width = 30,
}

styles.rcalc_multiplier_holder_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 2,
}

styles.rcalc_multiplier_textfield = {
  type = "textbox_style",
  parent = "short_number_textfield",
  width = 40,
  horizontal_align = "center",
}

styles.rcalc_multiplier_nudge_buttons_flow = {
  type = "vertical_flow_style",
  vertical_spacing = 0,
  top_margin = 2,
}

styles.rcalc_multiplier_nudge_button = {
  type = "button_style",
  parent = "tool_button",
  width = 20,
  height = 14,
  padding = -1,
}

styles.rcalc_rates_table_scroll_pane = {
  type = "scroll_pane_style",
  parent = "flib_naked_scroll_pane",
  maximal_height = 600,
  top_padding = 8,
  bottom_padding = 8,
  minimal_height = 36,
  vertical_flow_style = {
    type = "vertical_flow_style",
    horizontal_align = "center",
    vertical_align = "center",
  },
}

styles.rcalc_rates_table_horizontal_flow = {
  type = "horizontal_flow_style",
  horizontal_spacing = 8,
}

styles.rcalc_rates_table_vertical_flow = {
  type = "vertical_flow_style",
  vertical_spacing = 8,
}

styles.rcalc_rates_table_row_flow = {
  type = "horizontal_flow_style",
  vertical_align = "center",
  horizontal_spacing = 8,
  top_padding = 4,
  bottom_padding = 4,
}

styles.rcalc_completion_checkbox = {
  type = "checkbox_style",
  right_margin = 8,
}

styles.rcalc_transparent_slot = {
  type = "button_style",
  parent = "transparent_slot",
  right_margin = 8,
}

styles.rcalc_transparent_slot_no_shadow = {
  type = "button_style",
  parent = "rcalc_transparent_slot",
  draw_shadow_under_picture = false,
}

styles.rcalc_machines_label = {
  type = "label_style",
  font = "default-semibold",
  vertical_align = "center",
  height = 32,
}

styles.rcalc_intermediate_breakdown_label = {
  type = "label_style",
  parent = "rcalc_rate_label",
  font = "default-small-semibold",
  top_padding = 2,
  width = 95,
}

styles.rcalc_rate_label = {
  type = "label_style",
  parent = "rcalc_machines_label",
  horizontal_align = "right",
  width = 71,
}

styles.rcalc_negative_subfooter_frame = {
  type = "frame_style",
  parent = "subfooter_frame",
  graphical_set = {
    base = {
      center = { position = { 411, 25 }, size = { 1, 1 } },
      top = { position = { 411, 17 }, size = { 1, 8 } },
    },
    shadow = top_shadow, --- @diagnostic disable-line: undefined-global
  },
  left_padding = 12,
  bottom_padding = 4,
  horizontally_stretchable = "on",
  height = 0,
}
