local styles = data.raw["gui-style"].default

styles.rcalc_units_choose_elem_button = {
  type = "button_style",
  parent = "flib_slot_button_default",
  height = 30,
  width = 30,
}

styles.rcalc_warning_flow = {
  type = "horizontal_flow_style",
  padding = 12,
  height = 38,
  horizontal_align = "center",
  vertical_align = "center",
  vertical_spacing = 8,
  horizontally_stretchable = "on",
  vertically_stretchable = "on",
}

styles.rcalc_warning_frame_in_shallow_frame = {
  type = "frame_style",
  parent = "deep_frame_in_shallow_frame",
  graphical_set = {
    base = {
      position = { 85, 0 },
      corner_size = 8,
      center = { position = { 411, 25 }, size = { 1, 1 } },
      draw_type = "outer",
    },
    shadow = default_inner_shadow,
  },
}

styles.rcalc_slot_button_filtered = {
  type = "button_style",
  parent = "flib_slot_button_default",
  draw_grayscale_picture = true,
}

styles.rcalc_transparent_slot_filtered = {
  type = "button_style",
  parent = "transparent_slot",
  draw_grayscale_picture = true,
}
