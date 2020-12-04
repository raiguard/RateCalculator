local gui = require("__flib__.gui-beta")
local math = require("__flib__.math")
local table = require("__flib__.table")

local fixed_format = require("lib.fixed-precision-format")

local constants = require("constants")

local rates_gui = {}

local function stacked_labels(labels)
  return {
    type = "flow",
    style_mods = {
      horizontal_align = "center",
      vertical_align = "center",
      vertical_spacing = -4,
      top_margin = -2,
      bottom_margin = -2
    },
    direction = "vertical",
    children = table.map(labels, function(label)
      return {
        type = "label",
        style = "rcalc_amount_label",
        style_mods = {font_color = label.color},
        caption = label.caption
      }
    end)
  }
end

local function frame_action_button(sprite, action, ref)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite.."_white",
    hovered_sprite = sprite.."_black",
    clicked_sprite = sprite.."_black",
    mouse_button_filter = {"left"},
    ref = ref,
    actions = {
      on_click = action
    }
  }
end

function rates_gui.build(player, player_table)
  local demo_data = {
    sprite = "item/iron-plate",
    input_rate = 120.010,
    output_rate = 125.335,
    input_machines = 21,
    output_machines = 3
  }

  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      visible = false,
      ref = {"window"},
      actions = {
        on_closed = {gui = "rates", action = "close"}
      },
      children = {
        {type = "flow", ref = {"titlebar_flow"}, children = {
          {type = "label", style = "frame_title", caption = {"mod-name.RateCalculator"}, ignored_by_interaction = true},
          {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
          frame_action_button("rc_pin", {gui = "rates", action = "toggle_pinned"}, {"pin_button"}),
          frame_action_button("utility/close", {gui = "rates", action = "close"})
        }},
        {type = "frame", style = "inside_shallow_frame", direction = "vertical", children = {
          {type = "frame", style = "rcalc_toolbar_frame", children = {
            {type = "label", style = "subheader_caption_label", caption = {"rcalc-gui.measure-label"}},
            {
              type = "drop-down",
              items = constants.measures_dropdown,
              ref = {"measure_dropdown"},
              actions = {
                on_selection_state_changed = {gui = "rates", action = "update_measure"}
              }
            },
            {type = "empty-widget", style = "flib_horizontal_pusher"},
            {
              type = "flow",
              style_mods = {horizontal_spacing = 12, vertical_align = "center"},
              ref = {"units_flow"},
              children = {
                {type = "label", style = "caption_label", caption = {"rcalc-gui.units-label"}},
                {
                  type = "choose-elem-button",
                  style = "rcalc_units_choose_elem_button",
                  style_mods = {right_margin = -8},
                  elem_type = "entity",
                  ref = {"units_button"},
                  actions = {
                    on_elem_changed = {gui = "rates", action = "update_units_button"}
                  }
                },
                {
                  type = "drop-down",
                  ref = {"units_dropdown"},
                  actions = {
                    on_selection_state_changed = {gui = "rates", action = "update_units_dropdown"}
                  }
                }
              }
            },
          }},
          {type = "scroll-pane", style = "flib_naked_scroll_pane", children = {
            {type = "frame", style = "rcalc_rates_list_box_frame", direction = "vertical", children = {
              {type = "frame", style = "rcalc_toolbar_frame", style_mods = {right_padding = 20}, children = {
                {type = "label", style = "rcalc_column_label", style_mods = {width = 32}, caption = "--"},
                {type = "label", style = "rcalc_column_label", caption = {"rcalc-gui.rate"}},
                {type = "label", style = "rcalc_column_label", caption = {"rcalc-gui.machines"}},
                {type = "label", style = "rcalc_column_label", caption = {"rcalc-gui.per-machine"}},
                {type = "label", style = "rcalc_column_label", caption = {"rcalc-gui.net-rate"}},
                {type = "label", style = "rcalc_column_label", caption = {"rcalc-gui.net-machines"}}
              }},
              {
                type = "scroll-pane",
                style = "rcalc_rates_list_box_scroll_pane",
                ref = {"scroll_pane"},
                -- TESTING
                children = {
                  {type = "frame", style = "rcalc_rates_list_box_row_frame", style_mods = {horizontally_stretchable = true}, children = {
                    {
                      type = "sprite-button",
                      style = "rcalc_row_button",
                      sprite = demo_data.sprite,
                      enabled = false
                    },
                    stacked_labels{
                      {color = constants.colors.output, caption = fixed_format(demo_data.output_rate, 6, "2")},
                      {color = constants.colors.input, caption = fixed_format(-demo_data.input_rate, 5, "2")},
                    },
                    stacked_labels{
                      {color = constants.colors.output, caption = fixed_format(demo_data.output_machines, 6, "2")},
                      {color = constants.colors.input, caption = fixed_format(-demo_data.input_machines, 5, "2")},
                    },
                    stacked_labels{
                      {color = constants.colors.output, caption = fixed_format(math.round_to(demo_data.output_rate / demo_data.output_machines, 4), 6, "2")},
                      {color = constants.colors.input, caption = fixed_format(-math.round_to(demo_data.input_rate / demo_data.input_machines, 5), 5, "2")},
                    },
                    stacked_labels{
                      {caption = fixed_format(demo_data.output_rate - demo_data.input_rate, 6, "2")},
                    },
                    stacked_labels{
                      {caption = fixed_format(demo_data.output_machines - demo_data.input_machines, 5, "2")},
                    }
                  }}
                }
              }
            }}
          }}
        }}
      }
    }
  })

  refs.titlebar_flow.drag_target = refs.window
  refs.window.force_auto_center()

  -- assemble default settings table
  local measure = next(constants.measures)
  local units = {}
  for measure_name, units_list in pairs(constants.units) do
    local measure_settings = {}
    for unit_name, unit_data in pairs(units_list) do
      if unit_data.default then
        measure_settings.selected = unit_name
      end
      if unit_data.entity_filters and not unit_data.default_units then
        -- get the first entry in the table - `next()` does not work here since it's a LuaCustomTable
        for name in pairs(game.get_filtered_entity_prototypes(unit_data.entity_filters)) do
          measure_settings[unit_name] = name
          break
        end
      end
    end
    units[measure_name] = measure_settings
  end

  player_table.guis.rates = {
    refs = refs,
    state = {
      measure = measure,
      pinned = false,
      pinning = false,
      units = units,
      visible = false
    }
  }
end

function rates_gui.destroy(player_table)
  player_table.gui.rates.refs.window.destroy()
  player_table.gui.rates = nil
end

function rates_gui.open(player, player_table)
  local gui_data = player_table.guis.rates
  gui_data.state.visible = true
  gui_data.refs.window.visible = true

  if not gui_data.state.pinned then
    player.opened = gui_data.refs.window
  end
end

function rates_gui.close(player, player_table)
  local gui_data = player_table.guis.rates

  if not gui_data.state.pinning then
    -- de-focus the dropdowns if they were focused
    gui_data.refs.window.focus()

    gui_data.state.visible = false
    gui_data.refs.window.visible = false

    if player.opened == gui_data.refs.window then
      player.opened = nil
    end
  end
end

function rates_gui.update(player, player_table, to_measure)
  local gui_data = player_table.guis.rates
  local refs = gui_data.refs
  local state = gui_data.state

  -- update active measure if needed
  if to_measure then
    state.measure = to_measure
  end

  -- get unit data and update toolbar elements

  local measure = state.measure
  local measure_units = constants.units[measure]
  local units

  refs.measure_dropdown.selected_index = constants.measures[measure].index

  if measure_units then
    local units_button = refs.units_button
    local units_settings = state.units[measure]
    local selected_units = units_settings.selected
    local units_info = measure_units[selected_units]
    if units_info.entity_filters then
      -- get the data for the currently selected thing
      local currently_selected = units_settings[selected_units]
      if currently_selected then
        units = global.entity_rates[selected_units][currently_selected]
      else
        units = units_info.default_units
      end

      units_button.visible = true
      units_button.elem_filters = units_info.entity_filters
      units_button.elem_value = currently_selected
    else
      units = units_info.default_units
      units_button.visible = false
    end

    refs.units_flow.visible = true

    local units_dropdown = refs.units_dropdown
    units_dropdown.items = constants.units_dropdowns[measure]
    units_dropdown.selected_index = units_info.index
  else
    units = {
      multiplier = 1,
      divisor = 1
    }

    refs.units_flow.visible = false
  end

  local rates = player_table.selection[measure]

end

function rates_gui.handle_action(e, msg)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.guis.rates
  local refs = gui_data.refs
  local state = gui_data.state

  local action = msg.action
  if action == "open" then
    rates_gui.open(player, player_table)
  elseif action == "close" then
    rates_gui.close(player, player_table)
  elseif action == "toggle_pinned" then
    state.pinned = not state.pinned

    if state.pinned then
      state.pinning = true
      player.opened = nil
      state.pinning = false

      refs.pin_button.style = "flib_selected_frame_action_button"
      refs.pin_button.sprite = "rc_pin_black"
    else
      player.opened = refs.window
      refs.window.force_auto_center()

      refs.pin_button.style = "frame_action_button"
      refs.pin_button.sprite = "rc_pin_white"
    end
  elseif action == "update_measure" then
    local new_measure = constants.measures_arr[e.element.selected_index]
    state.measure = new_measure
    rates_gui.update(player, player_table)
  elseif action == "update_units_button" then
    local elem_value = e.element.elem_value
    local units_settings = state.units[state.measure]
    if elem_value then
      units_settings[units_settings.selected] = elem_value
      rates_gui.update(player, player_table)
    elseif not constants.units[state.measure][units_settings.selected].default_units then
      e.element.elem_value = units_settings[units_settings.selected]
    else
      units_settings[units_settings.selected] = nil
      rates_gui.update(player, player_table)
    end
  elseif action == "update_units_dropdown" then
    local new_units = constants.units_arrs[state.measure][e.element.selected_index]
    state.units[state.measure].selected = new_units
    rates_gui.update(player, player_table)
  end
end

return rates_gui