local gui = require("__flib__.gui-beta")
local math = require("__flib__.math")
local table = require("__flib__.table")

local fixed_format = require("lib.fixed-precision-format")

local constants = require("constants")

-- NOTE: flib's `delineate_number` is borked
-- Add commas to separate thousands
-- From lua-users.org: http://lua-users.org/wiki/FormattingNumbers
-- Credit http://richard.warburton.it
local function comma_value(input)
  local left, num, right = string.match(input, "^([^%d]*%d)(%d*)(.-)$")
  return left .. (num:reverse():gsub("(%d%d%d)", "%1,"):reverse()) .. right
end

local function format_tooltip(amount)
  return comma_value(math.round_to(amount, 3)):gsub(" $", "")
end

local function format_caption(amount, precision)
  return fixed_format(amount, precision and precision or (5 - (amount < 0 and 1 or 0)), "2")
end

local function total_label(label)
  return {
    type = "flow",
    style = "rcalc_totals_labels_flow",
    children = {
      { type = "label", style = "bold_label", caption = label },
      { type = "label" },
    },
  }
end

local function stacked_labels(width)
  return {
    type = "flow",
    style = "rcalc_stacked_labels_flow",
    style_mods = { width = width },
    direction = "vertical",
    children = {
      {
        type = "label",
        style = "rcalc_amount_label",
        style_mods = { font_color = constants.colors.output },
      },
      {
        type = "label",
        style = "rcalc_amount_label",
        style_mods = { font_color = constants.colors.input },
      },
    },
  }
end

local function frame_action_button(sprite, tooltip, action, ref)
  return {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = sprite .. "_white",
    hovered_sprite = sprite .. "_black",
    clicked_sprite = sprite .. "_black",
    tooltip = tooltip,
    mouse_button_filter = { "left" },
    ref = ref,
    actions = {
      on_click = action,
    },
  }
end

local function set_warning(refs, caption)
  if caption then
    refs.list_frame.style = "rcalc_warning_frame_in_shallow_frame"
    refs.scroll_pane.visible = false
    refs.warning_flow.visible = true
    refs.warning_label.caption = caption
  else
    refs.list_frame.style = "deep_frame_in_shallow_frame"
    refs.scroll_pane.visible = true
    refs.warning_flow.visible = false
  end
end

--- @class SelectionGui
local SelectionGui = {}

SelectionGui.actions = require("actions")

function SelectionGui:destroy()
  self.player_table.guis.selection.refs.window.destroy()
  self.player_table.guis.selection = nil
end

function SelectionGui:open()
  local gui_data = self.player_table.guis.selection
  gui_data.state.visible = true
  gui_data.refs.window.visible = true

  if not gui_data.state.pinned then
    player.opened = gui_data.refs.window
  end
end

function SelectionGui:dispatch(msg, e)
  local handler = self.actions[msg.action]
  if handler then
    handler(self, msg, e)
  end
end

--- @param reset_multiplier boolean
--- @param to_measure string|nil
function SelectionGui:update(reset_multiplier, to_measure)
  local gui_data = self.player_table.guis.selection
  local refs = gui_data.refs
  local state = gui_data.state

  -- Reset multiplier if a new selection was made
  if reset_multiplier then
    state.multiplier = 1
    refs.multiplier_textfield.style = "rcalc_multiplier_textfield"
    refs.multiplier_textfield.text = "1"
    refs.multiplier_slider.slider_value = 1
  end

  -- Update active measure if needed
  if to_measure then
    state.measure = to_measure
  end

  -- Get unit data and update toolbar elements

  local measure = state.measure
  local measure_units = constants.units[measure]
  local units

  refs.measure_dropdown.selected_index = constants.measures[measure].index

  -- Unset active warning, if there is one
  set_warning(refs, nil)

  local units_button = refs.units_button
  local units_settings = state.units[measure]
  local selected_units = units_settings.selected
  local units_info = measure_units[selected_units]
  local selection_tool_button = refs.selection_tool_button
  if units_info.entity_filters then
    -- Get the data for the currently selected thing
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
    local selected_inserter = self.player_table.selected_inserter
    if selected_inserter then
      units = { divisor = selected_inserter.rate, multiplier = 1, types = { item = true } }
      selection_tool_button.elem_value = selected_inserter.name
    else
      set_warning(refs, { "gui.rcalc-click-to-select-inserter" })
      selection_tool_button.elem_value = nil
    end
  else
    units = units_info.default_units
    units_button.visible = false
    selection_tool_button.visible = false
  end

  local units_dropdown = refs.units_dropdown
  local dropdown_items = constants.units_dropdowns[measure]
  if #dropdown_items == 1 then
    units_dropdown.enabled = false
  else
    units_dropdown.enabled = true
  end
  units_dropdown.items = dropdown_items
  units_dropdown.selected_index = units_info.index

  -- Update rates table

  local output_total = 0
  local input_total = 0

  if units then
    local rates = self.player_table.selection[measure]
    local scroll_pane = refs.scroll_pane
    local children = scroll_pane.children

    local widths = constants.widths[self.player_table.locale or "en"] or constants.widths.en

    local item_prototypes = game.item_prototypes
    local stack_sizes_cache = {}

    local search_query = state.search_query

    local function apply_units(obj_data)
      local output = {}
      for i, kind in ipairs({ "output", "input" }) do
        local amount = obj_data[kind .. "_amount"]
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

    local i = 0
    for _, data in ipairs(rates) do
      -- TODO: use translations
      if
        (data.input_amount > 0 or data.output_amount > 0)
        and (not units.types or units.types[data.type])
        and string.find(string.gsub(data.name, "%-", " "), search_query, 1, true)
      then
        i = i + 1
        local frame = children[i]
        if not frame then
          frame = gui.add(scroll_pane, {
            type = "frame",
            style = "rcalc_rates_list_box_row_frame_" .. (i % 2 == 0 and "even" or "odd"),
            {
              type = "sprite-button",
              style = "transparent_slot",
            },
            stacked_labels(widths[1]),
            stacked_labels(widths[2]),
            stacked_labels(widths[3]),
            { type = "label", style = "rcalc_amount_label", style_mods = { width = widths[4] } },
            { type = "label", style = "rcalc_amount_label", style_mods = { width = widths[5] } },
          })
        end

        local output_amount, input_amount = apply_units(data)
        local output_machines = data.output_machines * state.multiplier
        local input_machines = data.input_machines * state.multiplier
        local output_per_machine = output_machines > 0 and (output_amount / output_machines) or 0
        local input_per_machine = input_machines > 0 and (input_amount / input_machines) or 0

        local show_net_rate = output_amount > 0 and input_amount < 0

        -- Add instead of subtract since the input amount is returned as negative
        local net_rate = show_net_rate and output_amount + input_amount or nil
        local net_machines = show_net_rate and net_rate / output_per_machine or nil

        output_total = output_total + output_amount
        input_total = input_total + input_amount

        gui.update(frame, {
          {
            -- We have to explicitly set it to `nil` here, you can't put nil values in a table
            cb = function(elem)
              elem.number = data.temperature
            end,
            elem_mods = {
              sprite = data.type .. "/" .. string.gsub(data.name, "%..*$", ""),
              tooltip = data.localised_name,
            },
          },
          {
            {
              elem_mods = {
                caption = format_caption(output_amount),
                tooltip = format_tooltip(output_amount),
                visible = data.output_amount ~= 0,
              },
            },
            {
              elem_mods = {
                caption = format_caption(input_amount),
                tooltip = format_tooltip(input_amount),
                visible = data.input_amount ~= 0,
              },
            },
          },
          {
            {
              elem_mods = {
                caption = format_caption(output_machines, 1),
                tooltip = format_tooltip(output_machines),
                visible = output_machines > 0,
              },
            },
            {
              elem_mods = {
                caption = format_caption(input_machines, 1),
                tooltip = format_tooltip(input_machines),
                visible = input_machines > 0,
              },
            },
          },
          {
            {
              elem_mods = {
                caption = format_caption(output_per_machine or 0),
                tooltip = format_tooltip(output_per_machine or 0),
                visible = data.output_amount ~= 0,
              },
            },
            {
              elem_mods = {
                caption = format_caption(input_per_machine or 0),
                tooltip = format_tooltip(input_per_machine or 0),
                visible = data.input_amount ~= 0,
              },
            },
          },
          {
            style_mods = {
              font_color = (
                  net_rate and constants.colors[net_rate < 0 and "input" or (net_rate > 0 and "output" or "white")]
                  or constants.colors.white
                ),
            },
            elem_mods = {
              caption = show_net_rate and format_caption(net_rate) or "--",
              tooltip = show_net_rate and format_tooltip(net_rate) or "",
            },
          },
          {
            style_mods = {
              font_color = (
                  net_machines
                    and constants.colors[net_machines < 0 and "input" or (net_machines > 0 and "output" or "white")]
                  or constants.colors.white
                ),
            },
            elem_mods = {
              caption = show_net_rate and format_caption(net_machines) or "--",
              tooltip = show_net_rate and format_tooltip(net_machines) or "",
            },
          },
        })
      end
    end

    for j = i + 1, #children do
      children[j].destroy()
    end

    if i == 0 then
      if #search_query > 0 then
        set_warning(refs, { "gui.rcalc-no-search-results" })
      else
        set_warning(refs, { "gui.rcalc-no-rates" })
      end
    end
  end

  -- Input total is negative, so add instead of subtract
  local net_total = output_total + input_total

  -- Update totals
  if units and units_info.show_totals then
    gui.update(refs.totals_frame, {
      elem_mods = { visible = true },
      {},
      {},
      {
        {},
        {
          elem_mods = {
            caption = format_caption(output_total),
            tooltip = format_tooltip(output_total),
          },
        },
      },
      {},
      {
        {},
        {
          elem_mods = {
            caption = format_caption(input_total),
            tooltip = format_tooltip(input_total),
          },
        },
      },
      {},
      {
        {},
        {
          elem_mods = {
            caption = format_caption(net_total),
            tooltip = format_tooltip(net_total),
          },
        },
      },
    })
  else
    refs.totals_frame.visible = false
  end
end

local index = {}

function index.build(player, player_table)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      direction = "vertical",
      visible = false,
      ref = { "window" },
      actions = {
        on_closed = { gui = "selection", action = "close" },
      },
      {
        type = "flow",
        style = "flib_titlebar_flow",
        ref = { "titlebar_flow" },
        actions = {
          on_click = { gui = "selection", action = "recenter" },
        },
        {
          type = "label",
          style = "frame_title",
          caption = { "mod-name.RateCalculator" },
          ignored_by_interaction = true,
        },
        { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
        {
          type = "textfield",
          style_mods = { top_margin = -3, width = 150 },
          visible = false,
          ref = { "search_textfield" },
          actions = {
            on_text_changed = { gui = "selection", action = "update_search_query" },
          },
        },
        frame_action_button(
          "utility/search",
          { "gui.rcalc-search-instruction" },
          { gui = "selection", action = "toggle_search" },
          { "search_button" }
        ),
        frame_action_button(
          "rc_pin",
          { "gui.rcalc-keep-open" },
          { gui = "selection", action = "toggle_pinned" },
          { "pin_button" }
        ),
        frame_action_button("utility/close", { "gui.close-instruction" }, { gui = "selection", action = "close" }),
      },
      {
        type = "frame",
        style = "inside_shallow_frame",
        direction = "vertical",
        {
          type = "frame",
          style = "rcalc_toolbar_frame",
          { type = "label", style = "subheader_caption_label", caption = { "gui.rcalc-measure-label" } },
          {
            type = "drop-down",
            items = constants.measures_dropdown,
            ref = { "measure_dropdown" },
            actions = {
              on_selection_state_changed = { gui = "selection", action = "update_measure" },
            },
          },
          { type = "empty-widget", style = "flib_horizontal_pusher" },
          { type = "label", style = "caption_label", caption = { "gui.rcalc-units-label" } },
          {
            type = "choose-elem-button",
            style = "rcalc_units_choose_elem_button",
            style_mods = { right_margin = -8 },
            elem_type = "entity",
            ref = { "units_button" },
            actions = {
              on_elem_changed = { gui = "selection", action = "update_units_button" },
            },
          },
          {
            type = "choose-elem-button",
            style = "rcalc_units_choose_elem_button",
            style_mods = { right_margin = -8 },
            elem_type = "entity",
            elem_mods = { locked = true },
            ref = { "selection_tool_button" },
            actions = {
              on_click = { gui = "selection", action = "give_selection_tool" },
            },
          },
          {
            type = "drop-down",
            ref = { "units_dropdown" },
            actions = {
              on_selection_state_changed = { gui = "selection", action = "update_units_dropdown" },
            },
          },
        },
        {
          type = "flow",
          style_mods = { padding = 12, margin = 0 },
          {
            type = "frame",
            style = "deep_frame_in_shallow_frame",
            direction = "vertical",
            ref = { "list_frame" },
            {
              type = "frame",
              style = "rcalc_toolbar_frame",
              style_mods = { right_padding = 20 },
              { type = "label", style = "rcalc_column_label", style_mods = { width = 32 }, caption = "--" },
              { type = "label", style = "rcalc_column_label", caption = { "gui.rcalc-rate" } },
              { type = "label", style = "rcalc_column_label", caption = { "gui.rcalc-machines" } },
              { type = "label", style = "rcalc_column_label", caption = { "gui.rcalc-per-machine" } },
              { type = "label", style = "rcalc_column_label", caption = { "gui.rcalc-net-rate" } },
              { type = "label", style = "rcalc_column_label", caption = { "gui.rcalc-net-machines" } },
            },
            {
              type = "scroll-pane",
              style = "rcalc_rates_list_box_scroll_pane",
              horizontal_scroll_policy = "never",
              ref = { "scroll_pane" },
            },
            {
              type = "flow",
              style = "rcalc_warning_flow",
              visible = false,
              ref = { "warning_flow" },
              {
                type = "label",
                style = "bold_label",
                caption = { "gui.rcalc-click-to-select-inserter" },
                ref = { "warning_label" },
              },
            },
            {
              type = "frame",
              style = "rcalc_totals_frame",
              ref = { "totals_frame" },
              { type = "label", style = "caption_label", caption = { "gui.rcalc-totals-label" } },
              { type = "empty-widget", style = "flib_horizontal_pusher" },
              total_label({ "gui.rcalc-output-label" }),
              { type = "empty-widget", style = "flib_horizontal_pusher" },
              total_label({ "gui.rcalc-input-label" }),
              { type = "empty-widget", style = "flib_horizontal_pusher" },
              total_label({ "gui.rcalc-net-label" }),
            },
          },
        },
        {
          type = "frame",
          style = "rcalc_multiplier_frame",
          {
            type = "label",
            style = "subheader_caption_label",
            caption = { "gui.rcalc-multiplier-label" },
          },
          {
            type = "slider",
            style = "rcalc_multiplier_slider",
            minimum_value = 1,
            maximum_value = 100,
            value_step = 1,
            ref = { "multiplier_slider" },
            actions = {
              on_value_changed = { gui = "selection", action = "update_multiplier_slider" },
            },
          },
          {
            type = "textfield",
            style = "rcalc_multiplier_textfield",
            numeric = true,
            allow_decimal = true,
            clear_and_focus_on_right_click = true,
            lose_focus_on_confirm = true,
            text = "1",
            ref = { "multiplier_textfield" },
            actions = {
              on_text_changed = { gui = "selection", action = "update_multiplier_textfield" },
            },
          },
        },
      },
    },
  })

  refs.titlebar_flow.drag_target = refs.window
  refs.window.force_auto_center()

  -- Assemble default settings table
  local measure = next(constants.measures)
  local units = {}
  for measure_name, units_list in pairs(constants.units) do
    local measure_settings = {}
    for unit_name, unit_data in pairs(units_list) do
      if unit_data.default then
        measure_settings.selected = unit_name
      end
      if unit_data.entity_filters and not unit_data.default_units then
        -- Get the first entry in the table - `next()` does not work here since it's a LuaCustomTable
        for name in pairs(game.get_filtered_entity_prototypes(unit_data.entity_filters)) do
          measure_settings[unit_name] = name
          break
        end
      end
    end
    units[measure_name] = measure_settings
  end

  --- @type SelectionGui
  local self = {
    player = player,
    player_table = player_table,
    refs = refs,
    state = {
      measure = measure,
      multiplier = 1,
      pinned = false,
      pinning = false,
      search_open = false,
      search_query = "",
      units = units,
      visible = false,
    },
  }

  setmetatable(self, { __index = SelectionGui })

  player_table.guis.selection = self
end

return index
