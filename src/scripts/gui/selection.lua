local gui = require("__flib__.gui-beta")
local math = require("__flib__.math")
local table = require("__flib__.table")

local fixed_format = require("lib.fixed-precision-format")

local constants = require("constants")

local selection_gui = {}

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

local function format_caption(amount, precision)
  return fixed_format(amount, precision and precision or (5 - (amount < 0 and 1 or 0)), "2")
end

local function total_label(label)
  return (
    {type = "flow", style = "rcalc_totals_labels_flow", children = {
      {type = "label", style = "bold_label", caption = label},
      {type = "label"},
    }}
  )
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

local function frame_action_button(sprite, tooltip, action, ref)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite.."_white",
    hovered_sprite = sprite.."_black",
    clicked_sprite = sprite.."_black",
    tooltip = tooltip,
    mouse_button_filter = {"left"},
    ref = ref,
    actions = {
      on_click = action
    }
  }
end

function selection_gui.build(player, player_table)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      visible = false,
      ref = {"window"},
      actions = {
        on_closed = {gui = "selection", action = "close"}
      },
      children = {
        {type = "flow", style = "flib_titlebar_flow", ref = {"titlebar_flow"}, children = {
          {type = "label", style = "frame_title", caption = {"mod-name.RateCalculator"}, ignored_by_interaction = true},
          {type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true},
          {
            type = "textfield",
            style_mods = {top_margin = -3, width = 150},
            visible = false,
            ref = {"search_textfield"},
            actions = {
              on_text_changed = {gui = "selection", action = "update_search_query"}
            }
          },
          frame_action_button(
            "utility/search",
            {"gui.rcalc-search-instruction"},
            {gui = "selection", action = "toggle_search"},
            {"search_button"}
          ),
          frame_action_button(
            "rc_pin",
            {"gui.rcalc-keep-open"},
            {gui = "selection", action = "toggle_pinned"},
            {"pin_button"}
          ),
          frame_action_button(
            "utility/close",
            {"gui.close-instruction"},
            {gui = "selection", action = "close"}
          )
        }},
        {type = "frame", style = "inside_shallow_frame", direction = "vertical", children = {
          {type = "frame", style = "rcalc_toolbar_frame", children = {
            {type = "label", style = "subheader_caption_label", caption = {"gui.rcalc-measure-label"}},
            {
              type = "drop-down",
              items = constants.measures_dropdown,
              ref = {"measure_dropdown"},
              actions = {
                on_selection_state_changed = {gui = "selection", action = "update_measure"}
              }
            },
            {type = "empty-widget", style = "flib_horizontal_pusher"},
            {type = "label", style = "caption_label", caption = {"gui.rcalc-units-label"}},
            {
              type = "choose-elem-button",
              style = "rcalc_units_choose_elem_button",
              style_mods = {right_margin = -8},
              elem_type = "entity",
              ref = {"units_button"},
              actions = {
                on_elem_changed = {gui = "selection", action = "update_units_button"}
              }
            },
            {
              type = "choose-elem-button",
              style = "rcalc_units_choose_elem_button",
              style_mods = {right_margin = -8},
              elem_type = "entity",
              elem_mods = {locked = true},
              ref = {"selection_tool_button"},
              actions = {
                on_click = {gui = "selection", action = "give_selection_tool"}
              }
            },
            {
              type = "drop-down",
              ref = {"units_dropdown"},
              actions = {
                on_selection_state_changed = {gui = "selection", action = "update_units_dropdown"}
              }
            }
          }},
          {type = "flow", style_mods = {padding = 12, margin = 0}, children = {
            {type = "frame", style = "rcalc_rates_list_box_frame", direction = "vertical", children = {
              {type = "frame", style = "rcalc_toolbar_frame", style_mods = {right_padding = 20}, children = {
                {type = "label", style = "rcalc_column_label", style_mods = {width = 32}, caption = "--"},
                {type = "label", style = "rcalc_column_label", caption = {"gui.rcalc-rate"}},
                {type = "label", style = "rcalc_column_label", caption = {"gui.rcalc-machines"}},
                {type = "label", style = "rcalc_column_label", caption = {"gui.rcalc-per-machine"}},
                {type = "label", style = "rcalc_column_label", caption = {"gui.rcalc-net-rate"}},
                {type = "label", style = "rcalc_column_label", caption = {"gui.rcalc-net-machines"}}
              }},
              {
                type = "scroll-pane",
                style = "rcalc_rates_list_box_scroll_pane",
                horizontal_scroll_policy = "never",
                ref = {"scroll_pane"}
              },
              {
                type = "frame",
                style = "negative_subheader_frame",
                style_mods = {height = 45},
                ref = {"warning_frame"},
                children = {
                  {type = "empty-widget", style = "flib_horizontal_pusher"},
                  {
                    type = "label",
                    style = "bold_label",
                    caption = {"", "[img=utility/warning_white] ", {"gui.rcalc-click-to-select-inserter"}}
                  },
                  {type = "empty-widget", style = "flib_horizontal_pusher"}
                }
              },
              {type = "frame", style = "rcalc_totals_frame", ref = {"totals_frame"}, children = {
                {type = "label", style = "caption_label", caption = {"gui.rcalc-totals-label"}},
                {type = "empty-widget", style = "flib_horizontal_pusher"},
                total_label{"gui.rcalc-output-label"},
                {type = "empty-widget", style = "flib_horizontal_pusher"},
                total_label{"gui.rcalc-input-label"},
                {type = "empty-widget", style = "flib_horizontal_pusher"},
                total_label{"gui.rcalc-net-label"}
              }}
            }}
          }},
          {type = "frame", style = "rcalc_multiplier_frame", children = {
            {
              type = "label",
              style = "subheader_caption_label",
              caption = {"gui.rcalc-multiplier-label"}
            },
            {
              type = "slider",
              style = "rcalc_multiplier_slider",
              minimum_value = 1,
              maximum_value = 100,
              value_step = 1,
              ref = {"multiplier_slider"},
              actions = {
                on_value_changed = {gui = "selection", action = "update_multiplier_slider"}
              }
            },
            {
              type = "textfield",
              style = "rcalc_multiplier_textfield",
              numeric = true,
              allow_decimal = true,
              clear_and_focus_on_right_click = true,
              lose_focus_on_confirm = true,
              text = "1",
              ref = {"multiplier_textfield"},
              actions = {
                on_text_changed = {gui = "selection", action = "update_multiplier_textfield"}
              }
            }
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

  player_table.guis.selection = {
    refs = refs,
    state = {
      measure = measure,
      multiplier = 1,
      pinned = false,
      pinning = false,
      search_open = false,
      search_query = "",
      units = units,
      visible = false
    }
  }
end

function selection_gui.destroy(player_table)
  player_table.guis.selection.refs.window.destroy()
  player_table.guis.selection = nil
end

function selection_gui.open(player, player_table)
  local gui_data = player_table.guis.selection
  gui_data.state.visible = true
  gui_data.refs.window.visible = true

  if not gui_data.state.pinned then
    player.opened = gui_data.refs.window
  end
end

function selection_gui.update(player_table, reset_multiplier, to_measure)
  local gui_data = player_table.guis.selection
  local refs = gui_data.refs
  local state = gui_data.state

  -- reset multiplier if a new selection was made
  if reset_multiplier then
    state.multiplier = 1
    refs.multiplier_textfield.style = "rcalc_multiplier_textfield"
    refs.multiplier_textfield.text = "1"
    refs.multiplier_slider.slider_value = 1
  end

  -- update active measure if needed
  if to_measure then
    state.measure = to_measure
  end

  -- get unit data and update toolbar elements

  local measure = state.measure
  local measure_units = constants.units[measure]
  local units

  refs.measure_dropdown.selected_index = constants.measures[measure].index

  local units_button = refs.units_button
  local units_settings = state.units[measure]
  local selected_units = units_settings.selected
  local units_info = measure_units[selected_units]
  local selection_tool_button = refs.selection_tool_button
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
    selection_tool_button.visible = false
  elseif units_info.selection_tool then
    units_button.visible = false
    selection_tool_button.visible = true

    -- TODO: Un-hardcode this if we add any more selection tools
    local selected_inserter = player_table.selected_inserter
    if not selected_inserter then
      refs.scroll_pane.visible = false
      refs.warning_frame.visible = true
      selection_tool_button.elem_value = nil
      return
    end
    units = {divisor = selected_inserter.rate, multiplier = 1, types = {item = true}}
    selection_tool_button.elem_value = selected_inserter.name
  else
    units = units_info.default_units
    units_button.visible = false
    selection_tool_button.visible = false
  end

  -- In case they were hidden
  refs.scroll_pane.visible = true
  refs.warning_frame.visible = false

  local units_dropdown = refs.units_dropdown
  local dropdown_items = constants.units_dropdowns[measure]
  if #dropdown_items == 1 then
    units_dropdown.enabled = false
  else
    units_dropdown.enabled = true
  end
  units_dropdown.items = dropdown_items
  units_dropdown.selected_index = units_info.index

  -- update rates table

  local rates = player_table.selection[measure]
  local scroll_pane = refs.scroll_pane
  local children = scroll_pane.children

  local widths = constants.widths[player_table.locale or "en"] or constants.widths.en

  local item_prototypes = game.item_prototypes
  local stack_sizes_cache = {}

  local search_query = state.search_query

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
      output[i] = (amount / units.divisor) * units.multiplier * state.multiplier * (kind == "input" and -1 or 1)
    end

    return table.unpack(output)
  end

  -- TODO: sort the table somehow

  local output_total = 0
  local input_total = 0

  local i = 0
  for _, data in ipairs(rates) do
    if data.input_amount == 0 and data.output_amount == 0 then goto continue end
    if units.types and not units.types[data.type] then goto continue end
    -- TODO: use translations
    if not string.find(string.gsub(data.name, "%-", " "), search_query, 1, true) then goto continue end

    i = i + 1
    local frame = children[i]
    if not frame then
      gui.build(scroll_pane, {
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
      frame = scroll_pane.children[i]
    end

    local output_amount, input_amount = apply_units(data)
    local output_machines = data.output_machines * state.multiplier
    local input_machines = data.input_machines * state.multiplier
    local output_per_machine = output_machines > 0 and (output_amount / output_machines) or 0
    local input_per_machine = input_machines > 0 and (input_amount / input_machines) or 0

    local show_net_rate = output_amount > 0 and input_amount < 0

    -- add instead of subtract since the input amount is returned as negative
    local net_rate = show_net_rate and output_amount + input_amount or nil
    local net_machines = show_net_rate and net_rate / output_per_machine or nil

    output_total = output_total + output_amount
    input_total = input_total + input_amount

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
            visible = output_machines > 0,
            caption = format_caption(output_machines, 1),
            tooltip = format_tooltip(output_machines)
          }},
          {elem_mods = {
            visible = input_machines > 0,
            caption = format_caption(input_machines, 1),
            tooltip = format_tooltip(input_machines)
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

  -- input total is negative, so add instead of subtract
  local net_total = output_total + input_total

  -- update totals
  if units_info.show_totals then
    gui.update(refs.totals_frame, (
      {
        elem_mods = {visible = true},
        children = {
          {},
          {},
          {children = {
            {},
            {elem_mods = {
              caption = format_caption(output_total),
              tooltip = format_tooltip(output_total)
            }}
          }},
          {},
          {children = {
            {},
            {elem_mods = {
              caption = format_caption(input_total),
              tooltip = format_tooltip(input_total)
            }}
          }},
          {},
          {children = {
            {},
            {elem_mods = {
              caption = format_caption(net_total),
              tooltip = format_tooltip(net_total)
            }}
          }}
        }
      }
    ))
  else
    refs.totals_frame.visible = false
  end
end

function selection_gui.update_table_rows(player, player_table)
  local rows = player.mod_settings["rcalc-rates-table-rows"].value
  local gui_data = player_table.guis.selection
  gui_data.refs.scroll_pane.style.height = rows * constants.row_height
end

function selection_gui.handle_action(e, msg)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local gui_data = player_table.guis.selection
  local refs = gui_data.refs
  local state = gui_data.state

  local action = msg.action
  if action == "open" then
    selection_gui.open(player, player_table)
  elseif action == "close" then
    if not state.pinning then
      -- close search if it was open
      if e.element.type ~= "sprite-button" and state.search_open then
        state.search_open = false
        state.search_query = ""
        local search_textfield = refs.search_textfield
        search_textfield.visible = false
        search_textfield.text = ""
        local search_button = refs.search_button
        search_button.style = "frame_action_button"
        search_button.sprite = "utility/search_white"
        if not state.pinned then
          player.opened = refs.window
        end
        selection_gui.update(player_table)
      else
        -- de-focus the dropdowns if they were focused
        refs.window.focus()

        state.visible = false
        refs.window.visible = false

        if player.opened == refs.window then
          player.opened = nil
        end
      end
    end
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
    selection_gui.update(player_table)
  elseif action == "update_units_button" then
    local elem_value = e.element.elem_value
    local units_settings = state.units[state.measure]
    if elem_value then
      units_settings[units_settings.selected] = elem_value
      selection_gui.update(player_table)
    elseif not constants.units[state.measure][units_settings.selected].default_units then
      e.element.elem_value = units_settings[units_settings.selected]
    else
      units_settings[units_settings.selected] = nil
      selection_gui.update(player_table)
    end
  elseif action == "update_units_dropdown" then
    local measure_unit_settings = state.units[state.measure]
    local new_units = constants.units_arrs[state.measure][e.element.selected_index]

    -- get old units and compare button groups
    local old_units_data = constants.units[state.measure][measure_unit_settings.selected]
    local new_units_data = constants.units[state.measure][new_units]
    local old_button_group = old_units_data.button_group
    local new_button_group = new_units_data.button_group
    if old_button_group and new_button_group and old_button_group == new_button_group then
      -- carry over button state
      measure_unit_settings[new_units] = measure_unit_settings[measure_unit_settings.selected]
    end

    measure_unit_settings.selected = new_units
    selection_gui.update(player_table)
  elseif action == "update_multiplier_slider" then
    local slider = refs.multiplier_slider
    local new_value = slider.slider_value
    if new_value ~= state.multiplier then
      refs.multiplier_textfield.style = "rcalc_multiplier_textfield"
      refs.multiplier_textfield.text = tostring(new_value)
      state.multiplier = new_value
      selection_gui.update(player_table)
    end
  elseif action == "update_multiplier_textfield" then
    local textfield = refs.multiplier_textfield
    local new_value = tonumber(textfield.text) or 0
    if new_value > 0 then
      textfield.style = "rcalc_multiplier_textfield"
      state.multiplier = new_value
      refs.multiplier_slider.slider_value = math.min(100, new_value)
      selection_gui.update(player_table)
    else
      textfield.style = "rcalc_invalid_multiplier_textfield"
    end
  elseif action == "toggle_search" then
    local to_state = not state.search_open
    state.search_open = to_state
    local search_button = refs.search_button
    search_button.style = to_state and "flib_selected_frame_action_button" or "frame_action_button"
    search_button.sprite = to_state and "utility/search_black" or "utility/search_white"
    local search_textfield = refs.search_textfield
    if to_state then
      search_textfield.visible = true
      search_textfield.focus()
    else
      search_textfield.visible = false
      search_textfield.text = ""
      state.search_query = ""
      selection_gui.update(player_table)
    end
  elseif action == "update_search_query" then
    state.search_query = e.text
    selection_gui.update(player_table)
  elseif action == "give_selection_tool" then
    if player.clear_cursor() then
      player.cursor_stack.set_stack{name = "rcalc-inserter-selector", count = 1}
      -- TODO: Update warning text
    end
  end
end

return selection_gui
