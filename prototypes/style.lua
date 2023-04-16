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
}
