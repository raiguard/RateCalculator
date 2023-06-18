local main_gui_width = 500

local styles = data.raw["gui-style"].default

styles.rcalc_negative_subfooter_frame = {
  type = "frame_style",
  parent = "subfooter_frame",
  graphical_set = {
    base = {
      center = { position = { 411, 25 }, size = { 1, 1 } },
      top = { position = { 411, 17 }, size = { 1, 8 } },
    },
    shadow = top_shadow,
  },
  left_padding = 12,
  bottom_padding = 4,
  horizontally_stretchable = "on",
}

styles.rcalc_completion_checkbox = {
  type = "checkbox_style",
  right_margin = 8,
}

styles.rcalc_machines_label = {
  type = "label_style",
  font = "default-semibold",
  vertical_align = "center",
  height = 32,
}

styles.rcalc_rate_label = {
  type = "label_style",
  parent = "rcalc_machines_label",
  horizontal_align = "right",
  width = 71,
}

styles.rcalc_rate_breakdown_label = {
  type = "label_style",
  parent = "rcalc_rate_label",
  font = "default-small",
  top_padding = 2,
}

styles.rcalc_rates_flow = {
  type = "horizontal_flow_style",
  vertical_align = "center",
  horizontal_spacing = 8,
  top_padding = 4,
  bottom_padding = 4,
}

styles.rcalc_rates_scroll_pane = {
  type = "scroll_pane_style",
  parent = "flib_naked_scroll_pane",
  maximal_height = 600,
  minimal_width = main_gui_width,
  top_padding = 8,
  bottom_padding = 8,
  minimal_height = 36,
  vertical_flow_style = {
    type = "vertical_flow_style",
    horizontal_align = "center",
    vertical_align = "center",
  },
}

styles.rcalc_transparent_slot = {
  type = "button_style",
  parent = "transparent_slot",
  right_margin = 8,
}

styles.rcalc_units_choose_elem_button = {
  type = "button_style",
  parent = "flib_slot_button_default",
  height = 30,
  width = 30,
}

styles.rcalc_titlebar_search_textfield = {
  type = "textbox_style",
  parent = "flib_titlebar_search_textfield",
  width = 100,
}
