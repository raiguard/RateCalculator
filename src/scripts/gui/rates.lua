local gui = require("__flib__.gui-beta")
local math = require("__flib__.math")
local table = require("__flib__.table")

local fixed_format = require("lib.fixed-precision-format")

local constants = require("constants")

local rates_gui = {}

-- add commas to separate thousands
-- from lua-users.org: http://lua-users.org/wiki/FormattingNumbers
-- credit http://richard.warburton.it
local function comma_value(input)
	local left, num, right = string.match(input,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

local function format_tooltip(amount)
  return comma_value(math.round_to(amount, 3)):gsub(" $", "")
end

local function format_caption(amount)
  return fixed_format(amount, 5 - (amount < 0 and 1 or 0), "2")
end

local function stacked_labels(width)
  return {
    type = "flow",
    style = "rcalc_stacked_labels_flow",
    style_mods = {width = width},
    direction = "vertical",
    children = {
      {
        type = "label",
        style = "rcalc_amount_label",
        style_mods = {font_color = constants.colors.output}
      },
      {
        type = "label",
        style = "rcalc_amount_label",
        style_mods = {font_color = constants.colors.input}
      }
    }
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
                ref = {"scroll_pane"}
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

function rates_gui.update(player_table, to_measure)
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

  -- update rates table

  local rates = player_table.selection[measure]
  local scroll_pane = refs.scroll_pane
  local children = scroll_pane.children

  local widths = constants.widths[player_table.locale]

  local item_prototypes = game.item_prototypes
  local stack_sizes_cache = {}

  local function apply_units(obj_data)
    local output = {}
    for i, kind in ipairs{"output", "input"} do
      local amount = obj_data[kind.."_amount"]
      if units.divide_by_stack_size then
        local stack_size = stack_sizes_cache[obj_data.name]
        if not stack_size then
          stack_size = item_prototypes[obj_data.name].stack_size
          stack_sizes_cache[obj_data.name] = stack_size
        end
        amount = amount / stack_size
      end
      output[i] = (amount / units.divisor) * units.multiplier * (kind == "input" and -1 or 1)
    end

    return table.unpack(output)
  end

  -- TODO: sort the table somehow

  local i = 0
  for _, data in pairs(rates) do
    if data.input_amount == 0 and data.output_amount == 0 then goto continue end
    if units.types and not units.types[data.type] then goto continue end

    i = i + 1
    local frame = children[i]
    if not frame then
      _, frame = gui.build(scroll_pane, {
        {type = "frame", style = "rcalc_rates_list_box_row_frame", children = {
          {
            type = "sprite-button",
            style = "rcalc_row_button",
            enabled = false
          },
          stacked_labels(widths[1]),
          stacked_labels(widths[2]),
          stacked_labels(widths[3]),
          {type = "label", style = "rcalc_amount_label", style_mods = {width = widths[4]}},
          {type = "label", style = "rcalc_amount_label", style_mods = {width = widths[5]}},
        }}
      })
    end

    local output_amount, input_amount = apply_units(data)
    local output_per_machine = data.output_machines > 0 and (output_amount / data.output_machines) or 0
    local input_per_machine = data.input_machines > 0 and (input_amount / data.input_machines) or 0

    local show_net_rate = output_amount > 0 and input_amount < 0

    -- add instead of subtract since the input amount is returned as negative
    local net_rate = show_net_rate and output_amount + input_amount or nil
    local net_machines = show_net_rate and net_rate / output_per_machine or nil


    gui.update(frame, (
      {children = {
        {elem_mods = {sprite = data.type.."/"..data.name, tooltip = data.localised_name}},
        {children = {
          {elem_mods = {
            visible = data.output_amount ~= 0,
            caption = format_caption(output_amount),
            tooltip = format_tooltip(output_amount)
          }},
          {elem_mods = {
            visible = data.input_amount ~= 0,
            caption = format_caption(input_amount),
            tooltip = format_tooltip(input_amount)
          }}
        }},
        {children = {
          {elem_mods = {
            visible = data.output_machines > 0,
            caption = format_tooltip(data.output_machines),
            tooltip = format_tooltip(data.output_machines)
          }},
          {elem_mods = {
            visible = data.input_machines > 0,
            caption = format_tooltip(data.input_machines),
            tooltip = format_tooltip(data.input_machines)
          }}
        }},
        {children = {
          {elem_mods = {
            visible = data.output_amount ~= 0,
            caption = format_caption(output_per_machine or 0),
            tooltip = format_tooltip(output_per_machine or 0)
          }},
          {elem_mods = {
            visible = data.input_amount ~= 0,
            caption = format_caption(input_per_machine or 0),
            tooltip = format_tooltip(input_per_machine or 0)
          }},
        }},
        {
          style_mods = {
            font_color = (
              net_rate
              and constants.colors[net_rate < 0 and "input" or (net_rate > 0 and "output" or "white")]
              or constants.colors.white
            )
          },
          elem_mods = {
            caption = show_net_rate and format_caption(net_rate) or "--",
            tooltip = show_net_rate and format_tooltip(net_rate) or ""
          }
        },
        {
          style_mods = {
            font_color = (
              net_machines
              and constants.colors[net_machines < 0 and "input" or (net_machines > 0 and "output" or "white")]
              or constants.colors.white
            )
          },
          elem_mods = {
            caption = show_net_rate and format_caption(net_machines) or "--",
            tooltip = show_net_rate and format_tooltip(net_machines) or ""
          }
        },
      }}
    ))

    ::continue::
  end

  for j = i + 1, #children do
    children[j].destroy()
  end
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
    rates_gui.update(player_table)
  elseif action == "update_units_button" then
    local elem_value = e.element.elem_value
    local units_settings = state.units[state.measure]
    if elem_value then
      units_settings[units_settings.selected] = elem_value
      rates_gui.update(player_table)
    elseif not constants.units[state.measure][units_settings.selected].default_units then
      e.element.elem_value = units_settings[units_settings.selected]
    else
      units_settings[units_settings.selected] = nil
      rates_gui.update(player_table)
    end
  elseif action == "update_units_dropdown" then
    local new_units = constants.units_arrs[state.measure][e.element.selected_index]
    state.units[state.measure].selected = new_units
    rates_gui.update(player_table)
  end
end

return rates_gui