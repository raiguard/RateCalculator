local styles = data.raw["gui-style"].default

styles.rcalc_content_pane = {
  type = "frame_style",
  parent = "inside_shallow_frame",
  graphical_set = {
    base = {
      position = { 17, 0 },
      corner_size = 8,
      center = { position = { 472, 25 }, size = { 1, 1 } },
      draw_type = "outer",
    },
    shadow = default_inner_shadow,
  },
}

styles.rcalc_ingredients_table = {
  type = "table_style",
  column_alignments = {
    { column = 1, alignment = "left" },
    { column = 2, alignment = "right" },
  },
  minimal_width = 120,
  horizontal_spacing = 0,
}

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

styles.rcalc_rate_label = {
  type = "label_style",
  font = "default-semibold",
  vertical_align = "center",
  height = 32,
  left_padding = 8,
}

styles.rcalc_rates_scroll_pane = {
  type = "scroll_pane_style",
  parent = "flib_naked_scroll_pane",
  top_padding = 8,
  right_padding = 12,
  bottom_padding = 8,
  left_padding = 12,
  maximal_height = 600,
  minimal_width = 374,
}

styles.rcalc_rates_table = {
  type = "table_style",
  column_alignments = {
    { column = 1, alignment = "left" },
    { column = 2, alignment = "left" },
    { column = 3, alignment = "right" },
  },
  minimal_width = 260,
  horizontal_spacing = 0,
}

styles.rcalc_transparent_slot = {
  type = "button_style",
  parent = "transparent_slot",
  right_padding = 14,
  width = 46,
}

styles.rcalc_transparent_slot_filtered = {
  type = "button_style",
  parent = "transparent_slot",
  draw_grayscale_picture = true,
  right_padding = 14,
  width = 46,
}

styles.rcalc_units_choose_elem_button = {
  type = "button_style",
  parent = "flib_slot_button_default",
  height = 30,
  width = 30,
}
