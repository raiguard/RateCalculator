local rcalc_gui = {}

local gui = require("__flib__.gui")

local constants = require("constants")

local fixed_format = require("lib.fixed-precision-format")

-- round a number to the nearest N decimal places
-- from lua-users.org: http://lua-users.org/wiki/FormattingNumbers
local function round(num, num_decimals)
  local mult = 10^(num_decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

-- add commas to separate thousands
-- from lua-users.org: http://lua-users.org/wiki/FormattingNumbers
-- credit http://richard.warburton.it
local function comma_value(input)
	local left, num, right = string.match(input,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

local function format_amount(amount)
  return fixed_format(amount, 4 - (amount < 0 and 1 or 0), "2"), comma_value(round(amount, 3))
end

gui.add_templates{
  column_label = {type="label", style="bold_label", style_mods={minimal_width=50, horizontal_align="center"}},
  frame_action_button = {type="sprite-button", style="frame_action_button", mouse_button_filter={"left"}},
  icon_column_header = {type="label", style="bold_label", style_mods={left_margin=4, width=31, horizontal_align="center"}, caption="--"},
  listbox_with_label = function(name, width, toolbar_children)
    return {type="flow", style_mods={vertical_spacing=6}, direction="vertical", children={
      {type="label", style="caption_label", style_mods={left_margin=2}, caption={"rcalc-gui."..name}},
      {type="frame", style="rcalc_material_list_box_frame", direction="vertical", save_as="panes."..name..".frame", children={
        {type="frame", style="rcalc_toolbar_frame", style_mods={width=width}, save_as="panes."..name..".toolbar", children=toolbar_children},
        {type="scroll-pane", style="rcalc_material_list_box_scroll_pane", save_as="panes."..name..".scroll_pane", children={
          {template="pushers.horizontal"}, -- dummy content; setting horizontally_stretchable on the scroll pane itself causes weirdness,
          {type="flow", style_mods={margin=0, padding=0, vertical_spacing=0}, direction="vertical", save_as="panes."..name..".content_flow"}
        }}
      }}
    }}
  end,
  pushers = {
    horizontal = {type="empty-widget", style_mods={horizontally_stretchable=true}}
  }
}

gui.add_handlers{
  close_button = {
    on_gui_click = function(e)
      rcalc_gui.close(game.get_player(e.player_index), global.players[e.player_index])
    end
  },
  pin_button = {
    on_gui_click = function(e)
      local player = game.get_player(e.player_index)
      local player_table = global.players[e.player_index]
      local gui_data = player_table.gui
      if gui_data.pinned then
        gui_data.titlebar.pin_button.style = "frame_action_button"
        gui_data.pinned = false
        gui_data.window.force_auto_center()
        player.opened = gui_data.window
      else
        gui_data.titlebar.pin_button.style = "flib_selected_frame_action_button"
        gui_data.pinned = true
        player.opened = nil
      end
    end
  },
  units_choose_elem_button = {
    on_gui_elem_changed = function(e)
      local player = game.get_player(e.player_index)
      local player_table = global.players[e.player_index]
      local player_settings = player_table.settings
      player_settings[constants.units_to_setting_name[player_settings.units]] = e.element.elem_value
      rcalc_gui.update_contents(player, player_table)
    end
  },
  units_drop_down = {
    on_gui_selection_state_changed = function(e)
      local player = game.get_player(e.player_index)
      local player_table = global.players[e.player_index]
      player_table.settings.units = e.element.selected_index
      rcalc_gui.update_contents(player, player_table)
    end
  },
  window = {
    on_gui_closed = function(e)
      local player_table = global.players[e.player_index]
      if not player_table.gui.pinned then
        rcalc_gui.close(game.get_player(e.player_index), global.players[e.player_index])
      end
    end
  }
}

function rcalc_gui.create(player, player_table)
  local gui_data = gui.build(player.gui.screen, {
    {type="frame", direction="vertical", handlers="window", save_as="window", children={
      {type="flow", save_as="titlebar.flow", children={
        {type="label", style="frame_title", caption={"mod-name.RateCalculator"}, elem_mods={ignored_by_interaction=true}},
        {type="empty-widget", style="flib_titlebar_drag_handle", elem_mods={ignored_by_interaction=true}},
        {template="frame_action_button", tooltip={"rcalc-gui.keep-open"}, sprite="rc_pin_white", hovered_sprite="rc_pin_black", clicked_sprite="rc_pin_black",
          handlers="pin_button", save_as="titlebar.pin_button"},
        {template="frame_action_button", sprite="utility/close_white", hovered_sprite="utility/close_black", clicked_sprite="utility/close_black",
          handlers="close_button", save_as="titlebar.close_button"}
      }},
      {type="frame", style="inside_shallow_frame", direction="vertical", children={
        {type="frame", style="subheader_frame", children={
          {type="label", style="subheader_caption_label", style_mods={right_margin=4}, caption={"rcalc-gui.units"}},
          {template="pushers.horizontal"},
          {type="choose-elem-button", style="rcalc_choose_elem_button", elem_type="entity", handlers="units_choose_elem_button",
            save_as="toolbar.units_choose_elem_button"},
          {type="drop-down", items=constants.units_dropdown_contents, selected_index=player_table.settings.units, handlers="units_drop_down",
            save_as="toolbar.units_drop_down"},
        }},
        {type="flow", style_mods={padding=12, top_padding=5, horizontal_spacing=12}, children={
          gui.templates.listbox_with_label("inputs", 122, {
            {template="icon_column_header"},
            {template="column_label", caption={"rcalc-gui.rate"}, tooltip={"rcalc-gui.consumption-rate-description"}},
          }),
          gui.templates.listbox_with_label("outputs", 361, {
            {template="icon_column_header"},
            {template="column_label", caption={"rcalc-gui.rate"}, tooltip={"rcalc-gui.production-rate-description"}},
            {template="column_label", caption={"rcalc-gui.per-machine"}, tooltip={"rcalc-gui.per-machine-description"}},
            {template="column_label", caption={"rcalc-gui.net-rate"}, tooltip={"rcalc-gui.net-rate-description"}},
            {template="column_label", caption={"rcalc-gui.net-machines"}, tooltip={"rcalc-gui.net-machines-description"}},
          })
        }},
        {type="frame", style="subfooter_frame", save_as="info_frame", children={
          {type="label", style="rcalc_info_label", caption={"rcalc-gui.science-rates-for-current-research-only"}},
          {template="pushers.horizontal"}
        }}
      }}
    }}
  })

  gui_data.titlebar.flow.drag_target = gui_data.window

  gui_data.window.force_auto_center()
  gui_data.window.visible = false

  gui_data.pinned = false

  player_table.gui = gui_data
end

function rcalc_gui.destroy(player, player_table)
  gui.remove_player_filters(player.index)
  player_table.gui.window.destroy()
  player_table.gui = nil
end

function rcalc_gui.open(player, player_table)
  player_table.gui.window.visible = true
  player_table.gui_open = true

  if not player_table.gui.pinned then
    player.opened = player_table.gui.window
  end
end

function rcalc_gui.close(player, player_table)
  player_table.gui.window.visible = false
  player_table.flags.gui_open = false

  -- focus another element in case the dropdown was being used
  player_table.gui.window.focus()

  player_table.selection_data = nil
end

function rcalc_gui.update_contents(player, player_table)
  local gui_data = player_table.gui
  local rate_data = player_table.selection_data

  if not rate_data then return end

  local units = player_table.settings.units

  -- choose elem button
  local choose_elem_button = gui_data.toolbar.units_choose_elem_button
  local ceb_data = constants.choose_elem_buttons[units]
  local unit_data = global.unit_data[units]
  if ceb_data then
    local selected_entity = player_table.settings[ceb_data.type]
    unit_data = unit_data[selected_entity]
    choose_elem_button.visible = true
    choose_elem_button.elem_value = selected_entity
    choose_elem_button.elem_filters = ceb_data.filters
  else
    choose_elem_button.visible = false
  end

  local stack_sizes_cache = {}
  local item_prototypes = game.item_prototypes

  local function apply_unit_data(obj_data)
    local amount = obj_data.amount
    if unit_data.divide_by_stack_size then
      local stack_size = stack_sizes_cache[obj_data.name]
      if not stack_size then
        stack_size = item_prototypes[obj_data.name].stack_size
        stack_sizes_cache[obj_data.name] = stack_size
      end
      amount = amount / stack_size
    end
    return (amount / unit_data.divisor) * unit_data.multiplier
  end

  -- rates
  for _, category in ipairs{"inputs", "outputs"} do
    local content_flow = gui_data.panes[category].content_flow
    local children = content_flow.children
    local children_count = #children
    local i = 0
    for _, obj_data in ipairs(rate_data[category]) do
      local obj_type = obj_data.type
      local obj_name = obj_data.name
      local rate_fixed, per_machine_fixed, net_rate_fixed, net_machines_fixed = "--", "--", "--", "--"
      local icon_tt, rate_tt, per_machine_tt, net_rate_tt, net_machines_tt

      -- apply unit_data properties
      if unit_data.types[obj_data.type] then
        local amount = apply_unit_data(obj_data)

        rate_fixed, rate_tt = format_amount(amount)
        icon_tt = {"", obj_data.localised_name, "\n", {"rcalc-gui.n-machines", obj_data.machines}}

        if category == "outputs" then
          local per_machine = amount / obj_data.machines
          per_machine_fixed, per_machine_tt = format_amount(per_machine)

          local obj_input = rate_data.inputs[obj_data.type.."."..obj_data.name]
          if obj_input then
            local net_rate = amount - apply_unit_data(obj_input)
            net_rate_fixed, net_rate_tt = format_amount(net_rate)
            net_machines_fixed, net_machines_tt = format_amount((net_rate / per_machine))
          end
        end

        i = i + 1
        local frame = children[i]
        if frame then
          local frame_children = frame.children

          local icon = frame_children[1]
          icon.sprite = obj_type.."/"..obj_name
          icon.number = obj_data.machines
          icon.tooltip = icon_tt

          local rate_label = frame_children[2]
          rate_label.caption = rate_fixed
          rate_label.tooltip = rate_tt

          if category == "outputs" then
            local per_machine_label = frame_children[3]
            per_machine_label.caption = per_machine_fixed
            per_machine_label.tooltip = per_machine_tt

            local net_rate_label = frame_children[4]
            net_rate_label.caption = net_rate_fixed
            net_rate_label.tooltip = net_rate_tt

            local net_machines_label = frame_children[5]
            net_machines_label.caption = net_machines_fixed
            net_machines_label.tooltip = net_machines_tt
          end
        else
          gui.build(content_flow, {
            {type="frame", style="rcalc_material_info_frame", children={
              {type="sprite-button", style="rcalc_material_icon_button", style_mods={width=32, height=32}, sprite=obj_type.."/"..obj_name,
                number=obj_data.machines, tooltip=icon_tt, elem_mods={enabled=false}},
              {type="label", style="rcalc_amount_label", caption=rate_fixed, tooltip=rate_tt},
              {type="condition", condition=(category=="outputs"), children={
                {type="label", style="rcalc_amount_label", style_mods={width=75}, caption=per_machine_fixed, tooltip=per_machine_tt},
                {type="label", style="rcalc_amount_label", style_mods={width=49}, caption=net_rate_fixed, tooltip=net_rate_tt},
                {type="label", style="rcalc_amount_label", style_mods={width=72}, caption=net_machines_fixed, tooltip=net_machines_tt},
              }},
              {type="empty-widget", style_mods={horizontally_stretchable=true, left_margin=-12}}
            }}
          })
        end
      end
    end

    if i < children_count then
      for ni = i + 1, children_count do
        children[ni].destroy()
      end
    end
  end

  -- info frame
  if rate_data.includes_lab then
    gui_data.info_frame.visible = true
  else
    gui_data.info_frame.visible = false
  end
end

return rcalc_gui