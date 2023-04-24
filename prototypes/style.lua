local styles = data.raw["gui-style"].default

styles.rcalc_units_choose_elem_button = {
  type = "button_style",
  parent = "flib_slot_button_default",
  height = 30,
  width = 30,
}

styles.rcalc_slot_button_filtered = {
  type = "button_style",
  parent = "transparent_slot",
  draw_grayscale_picture = true,
}

styles.rcalc_rates_table = {
  type = "table_style",
  column_alignments = {
    { column = 1, alignment = "left" },
    { column = 2, alignment = "left" },
    { column = 3, alignment = "right" },
  },
  minimal_width = 230,
  horizontal_spacing = 0,
}

styles.rcalc_ingredients_table = {
  type = "table_style",
  column_alignments = {
    { column = 1, alignment = "left" },
    { column = 2, alignment = "right" },
  },
  minimal_width = 100,
  horizontal_spacing = 0,
  right_margin = 8,
}

styles.rcalc_transparent_slot = {
  type = "button_style",
  parent = "transparent_slot",
  right_padding = 14,
  width = 46,
}

styles.rcalc_rates_table_label = {
  type = "label_style",
  font = "default-semibold",
  vertical_align = "center",
  height = 32,
  left_padding = 8,
}
