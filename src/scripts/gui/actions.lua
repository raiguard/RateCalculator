local on_tick_n = require("__flib__.on-tick-n")

local constants = require("constants")

local actions = {}

--- @param Gui SelectionGui
function actions.open(Gui, _)
  Gui:open()
end

--- @param Gui SelectionGui
--- @param e on_gui_click
function actions.close(Gui, e)
  if not Gui.state.pinning then
    -- Close search if it was open
    if e.element.type ~= "sprite-button" and Gui.state.search_open then
      Gui.state.search_open = false
      Gui.state.search_query = ""
      local search_textfield = Gui.refs.search_textfield
      search_textfield.visible = false
      search_textfield.text = ""
      local search_button = Gui.refs.search_button
      search_button.style = "frame_action_button"
      search_button.sprite = "utility/search_white"
      if not Gui.state.pinned then
        Gui.player.opened = Gui.refs.window
      end
      Gui:update()
    else
      -- De-focus the dropdowns if they were focused
      Gui.refs.window.focus()

      Gui.state.visible = false
      Gui.refs.window.visible = false

      if Gui.player.opened == Gui.refs.window then
        Gui.player.opened = nil
      end
    end
  end
end

--- @param Gui SelectionGui
function actions.toggle_pinned(Gui, _)
  Gui.state.pinned = not Gui.state.pinned
  if Gui.state.pinned then
    Gui.state.pinning = true
    Gui.player.opened = nil
    Gui.state.pinning = false
    Gui.refs.pin_button.style = "flib_selected_frame_action_button"
    Gui.refs.pin_button.sprite = "rcalc_pin_black"
  else
    Gui.player.opened = Gui.refs.window
    Gui.refs.window.force_auto_center()
    Gui.refs.pin_button.style = "frame_action_button"
    Gui.refs.pin_button.sprite = "rcalc_pin_white"
  end
end

--- @param Gui SelectionGui
--- @param e on_gui_selection_state_changed
function actions.update_measure(Gui, e)
  local new_measure = constants.measures_arr[e.element.selected_index]
  Gui.state.measure = new_measure
  Gui:update()
end

--- @param Gui SelectionGui
--- @param e on_gui_elem_changed
function actions.update_units_button(Gui, e)
  local elem_value = e.element.elem_value
  local units_settings = Gui.state.units[Gui.state.measure]
  if elem_value then
    units_settings[units_settings.selected] = elem_value
    Gui:update()
  elseif not constants.units[Gui.state.measure][units_settings.selected].default_units then
    e.element.elem_value = units_settings[units_settings.selected]
  else
    units_settings[units_settings.selected] = nil
    Gui:update()
  end
end

--- @param Gui SelectionGui
--- @param e on_gui_selection_state_changed
function actions.update_units_dropdown(Gui, e)
  local measure_unit_settings = Gui.state.units[Gui.state.measure]
  local new_units = constants.units_arrs[Gui.state.measure][e.element.selected_index]

  -- Get old units and compare button groups
  local old_units_data = constants.units[Gui.state.measure][measure_unit_settings.selected]
  local new_units_data = constants.units[Gui.state.measure][new_units]
  local old_button_group = old_units_data.button_group
  local new_button_group = new_units_data.button_group
  if old_button_group and new_button_group and old_button_group == new_button_group then
    -- Carry over button Gui.state
    measure_unit_settings[new_units] = measure_unit_settings[measure_unit_settings.selected]
  end

  measure_unit_settings.selected = new_units
  Gui:update()
end

--- @param Gui SelectionGui
function actions.update_multiplier_slider(Gui, _)
  local slider = Gui.refs.multiplier_slider
  local new_value = slider.slider_value
  if new_value ~= Gui.state.multiplier then
    Gui.refs.multiplier_textfield.style = "rcalc_multiplier_textfield"
    Gui.refs.multiplier_textfield.text = tostring(new_value)
    Gui.state.multiplier = new_value
    Gui:update()
  end
end

--- @param Gui SelectionGui
function actions.update_multiplier_textfield(Gui, _)
  local textfield = Gui.refs.multiplier_textfield
  local new_value = tonumber(textfield.text) or 0
  if new_value > 0 then
    textfield.style = "rcalc_multiplier_textfield"
    Gui.state.multiplier = new_value
    Gui.refs.multiplier_slider.slider_value = math.min(100, new_value)
    Gui:update()
  else
    textfield.style = "rcalc_invalid_multiplier_textfield"
  end
end

--- @param Gui SelectionGui
function actions.toggle_search(Gui, _)
  local to_state = not Gui.state.search_open
  Gui.state.search_open = to_state
  local search_button = Gui.refs.search_button
  search_button.style = to_state and "flib_selected_frame_action_button" or "frame_action_button"
  search_button.sprite = to_state and "utility/search_black" or "utility/search_white"
  local search_textfield = Gui.refs.search_textfield
  if to_state then
    search_textfield.visible = true
    search_textfield.focus()
  else
    search_textfield.visible = false
    search_textfield.text = ""
    Gui.state.search_query = ""
    Gui:update()
  end
end

--- @param Gui SelectionGui
--- @param e on_gui_text_changed
function actions.update_search_query(Gui, e)
  Gui.state.search_query = e.text

  -- Remove scheduled update if one exists
  if Gui.state.update_results_ident then
    on_tick_n.remove(Gui.state.update_results_ident)
    Gui.state.update_results_ident = nil
  end

  if e.text == "" then
    -- Update now
    Gui:update()
  else
    -- Update in a while
    Gui.state.update_results_ident = on_tick_n.add(
      game.tick + constants.search_timeout,
      { action = "update_search_results", player_index = e.player_index }
    )
  end
end

--- @param Gui SelectionGui
function actions.update_search_results(Gui, _)
  Gui:update()
end

--- @param Gui SelectionGui
function actions.give_selection_tool(Gui, _)
  if Gui.player.clear_cursor() then
    Gui.player.cursor_stack.set_stack({ name = "rcalc-inserter-selector", count = 1 })
  end
end

--- @param Gui SelectionGui
--- @param e on_gui_click
function actions.recenter(Gui, e)
  if e.button == defines.mouse_button_type.middle then
    Gui.refs.window.force_auto_center()
  end
end

--- @param Gui SelectionGui
function actions.nav_backward(Gui, _)
  Gui.state.selection_index = math.min(Gui.state.selection_index + 1, constants.save_selections)
  Gui:update()
end

--- @param Gui SelectionGui
function actions.nav_forward(Gui, _)
  Gui.state.selection_index = math.max(Gui.state.selection_index - 1, 1)
  Gui:update()
end

return actions
