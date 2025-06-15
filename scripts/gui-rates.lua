local flib_dictionary = require("__flib__.dictionary")
local flib_format = require("__flib__.format")
local flib_gui = require("__flib__.gui")
local flib_math = require("__flib__.math")
local flib_table = require("__flib__.table")

local gui_util = require("scripts.gui-util")

--- @alias DisplayCategory
--- | "products"
--- | "intermediates"
--- | "ingredients"

--- @alias GenericPrototype LuaEntityPrototype|LuaFluidPrototype|LuaItemPrototype

--- @class RatesDisplayData: Rates
--- @field category DisplayCategory
--- @field path SpritePath
--- @field sorting_rate double
--- @field completed boolean
--- @field unit string?

--- @alias CategoryDisplayData table<DisplayCategory, RatesDisplayData>
--- @alias DisplayDataLookup table<string, RatesDisplayData>

local colors = {
  green = "150,255,150",
  red = "255,150,150",
  white = "255,255,255",
}

--- @param amount number
--- @param prefer_si boolean
--- @param positive_prefix boolean
--- @return string
local function format_number(amount, prefer_si, positive_prefix)
  local formatted = ""
  if prefer_si or math.abs(amount) >= 10000 then
    formatted = flib_format.number(amount, true)
  else
    local precision = 0.001
    if math.abs(amount) >= 1000 then
      precision = 1
    elseif math.abs(amount) >= 100 then
      precision = 0.1
    elseif math.abs(amount) >= 10 then
      precision = 0.01
    end
    formatted = flib_format.number(flib_math.round(amount, precision))
  end
  if positive_prefix and amount > 0 then
    formatted = "+" .. formatted
  end
  return formatted
end

--- @param counts MachineCounts
--- @param include_numbers boolean
--- @return string
local function build_machine_icons(counts, include_numbers)
  local output = ""
  for id, count in pairs(counts) do
    local name, quality = string.match(id, "(.-)/(.*)")
    output = output .. "[entity=" .. name .. ",quality=" .. quality .. "] "
    if include_numbers then
      output = output .. count .. "  "
    end
  end
  return output
end

--- @param rate Rate
--- @param color string
--- @param label LocalisedString
--- @param suffix LocalisedString
local function build_rate_tooltip(rate, color, label, suffix)
  return {
    "gui.rcalc-colored-caption",
    {
      "",
      {
        "gui.rcalc-tooltip-entry",
        label,
        { "", format_number(rate.rate, false, false), suffix },
      },
      {
        "gui.rcalc-parenthesized-caption",
        {
          "gui.rcalc-machines-caption",
          { "", format_number(rate.rate / rate.machines, false, false), suffix },
          {
            "gui.rcalc-caption-with-suffix",
            format_number(rate.machines, false, false),
            { "gui.rcalc-machines" },
          },
        },
      },
    },
    color,
  }
end

--- @param num number
--- @return string
local function get_net_color(num)
  if num > 0 then
    return colors.green
  elseif num < 0 then
    return colors.red
  else
    return colors.white
  end
end

--- @param e EventData.on_gui_click
local function on_completion_checkbox_checked(e)
  local self = storage.gui[e.player_index]
  if not self then
    return
  end
  local set = self.sets[self.selected_set_index]
  if set then
    set.completed[e.element.name] = e.element.state or nil
  end
end

--- @param e EventData.on_gui_click
local function on_rates_flow_clicked(e)
  if not e.alt then
    return
  end
  if not remote.interfaces["RecipeBook"] or remote.call("RecipeBook", "version") ~= 5 then
    return
  end
  --- @type string, string
  local type, name
  local icon_elem = e.element.icon
  if icon_elem.type == "choose-elem-button" then
    type = string.gsub(icon_elem.elem_type, "%-with%-quality", "")
    name = icon_elem.elem_value.name
  else
    local sprite = e.element.icon.sprite
    type, name = string.match(sprite, "(.*)/(.*)")
  end
  if not type or not name then
    return
  end
  local prototype = prototypes[type][name]
  if prototype then
    remote.call("RecipeBook", "open_page", e.player_index, prototype)
  end
end

--- @param e EventData.on_gui_hover
local function on_rates_flow_hovered(e)
  local self = storage.gui[e.player_index]
  if not self or not self.elems.rcalc_window.valid then
    return
  end

  local elem = e.element
  local path = elem.name
  local data = self.display_data_lookup[path]
  if not data then
    return
  end

  local category = data.category
  local output = data.output
  local input = data.input
  local unit = data.unit
  local suffix
  if unit then
    suffix = { "si-unit-symbol-" .. unit }
  else
    suffix = { "gui.rcalc-timescale-suffix-" .. self.selected_timescale }
  end
  --- @type Rate
  local category_rate = category == "ingredients" and input or output

  --- @type GenericPrototype
  local prototype = prototypes[data.type][data.name]

  local name = prototype.localised_name
  if data.temperature then
    name = {
      "",
      name,
      " (",
      format_number(data.temperature, false, false),
      { "si-unit-degree-celsius" },
      ")",
    }
  end
  if data.quality and data.quality ~= "normal" then
    name = {
      "",
      name,
      " (",
      prototypes.quality[data.quality].localised_name,
      ")",
    }
  end

  local machine_counts_caption = build_machine_icons(category_rate.machine_counts, true)

  --- @type LocalisedString
  local intermediate_breakdown_caption = { "" }
  if category == "intermediates" then
    machine_counts_caption = machine_counts_caption .. "→  " .. build_machine_icons(input.machine_counts, true)

    local net_rate = output.rate - input.rate
    rate_caption = {
      "gui.rcalc-colored-caption",
      {
        "",
        {
          "gui.rcalc-tooltip-entry",
          { "gui.rcalc-net-rate" },
          { "", format_number(net_rate, false, true), suffix },
        },
        {
          "gui.rcalc-parenthesized-caption",
          {
            "gui.rcalc-caption-with-suffix",
            format_number(net_rate / (output.rate / output.machines), false, true),
            { "gui.rcalc-machines" },
          },
        },
      },
      get_net_color(net_rate),
    }

    intermediate_breakdown_caption = {
      "",
      "\n\n",
      build_rate_tooltip(output, colors.green, { "gui.rcalc-production" }, suffix),
      "\n",
      build_rate_tooltip(input, colors.red, { "gui.rcalc-consumption" }, suffix),
    }
  else
    rate_caption = build_rate_tooltip(category_rate, colors.white, { "gui.rcalc-rate" }, suffix)
  end

  machine_counts_caption = machine_counts_caption .. "\n"

  elem.tooltip = {
    "",
    { "gui.rcalc-tooltip-title", name },
    machine_counts_caption,
    rate_caption,
    intermediate_breakdown_caption,
    remote.interfaces["RecipeBook"]
        and { "", "\n\n", { "gui.rcalc-open-in-recipe-book-instruction", { "mod-name.RecipeBook" } } }
      or nil,
  }
end

--- @param e EventData.on_gui_leave
local function on_rates_flow_left(e)
  e.element.tooltip = ""
end

flib_gui.add_handlers({
  on_completion_checkbox_checked = on_completion_checkbox_checked,
  on_rates_flow_clicked = on_rates_flow_clicked,
  on_rates_flow_hovered = on_rates_flow_hovered,
  on_rates_flow_left = on_rates_flow_left,
})

--- @param parent LuaGuiElement
--- @param category DisplayCategory
--- @param rates RatesDisplayData[]
--- @param show_machines boolean
--- @param show_checkboxes boolean
--- @param show_breakdown boolean
local function build_rates_table(parent, category, rates, show_machines, show_checkboxes, show_breakdown)
  --- @type flib.GuiElemDef
  local rates_table = { type = "table", style = "slot_table", column_count = 1 }

  for _, data in pairs(rates) do
    local output = data.output
    local input = data.input
    local category_rate = data.category == "ingredients" and input or output
    local raw_rate = category_rate.rate

    local machines = format_number(category_rate.machines, false, false)
    local machines_caption = {
      "gui.rcalc-machines-caption",
      build_machine_icons(category_rate.machine_counts, false),
      machines,
    }

    local rate_color = colors.white
    if category == "intermediates" then
      raw_rate = flib_math.round(output.rate - input.rate, 0.00001) -- Floating point sucks
      rate_color = get_net_color(raw_rate)
      local net_machines = raw_rate / (output.rate / output.machines)
      machines_caption = {
        "gui.rcalc-net-machines-caption",
        machines_caption,
        rate_color,
        format_number(net_machines, false, true),
      }
    end

    local rate_caption = format_number(raw_rate, data.unit ~= nil, category == "intermediates")

    local flow = {
      type = "flow",
      name = data.path,
      style = "rcalc_rates_table_row_flow",
      raise_hover_events = true,
      game_controller_interaction = defines.game_controller_interaction and defines.game_controller_interaction.always,
      handler = {
        [defines.events.on_gui_click] = on_rates_flow_clicked,
        [defines.events.on_gui_hover] = on_rates_flow_hovered,
        [defines.events.on_gui_leave] = on_rates_flow_left,
      },
    }

    if show_checkboxes then
      flow[#flow + 1] = {
        type = "checkbox",
        name = data.path,
        state = data.completed,
        handler = {
          [defines.events.on_gui_checked_state_changed] = on_completion_checkbox_checked,
        },
      }
    end

    local button_style = "rcalc_transparent_slot"
    if data.path == "item/rcalc-heat-dummy/normal" then
      button_style = "rcalc_transparent_slot_no_shadow"
    end

    flow[#flow + 1] = {
      type = "sprite-button",
      name = "icon",
      style = button_style,
      sprite = data.type .. "/" .. data.name,
      quality = data.quality,
      number = data.temperature,
      ignored_by_interaction = true,
    }

    if show_machines then
      flow[#flow + 1] = {
        type = "label",
        style = "rcalc_machines_label",
        caption = machines_caption,
        ignored_by_interaction = true,
      }
      flow[#flow + 1] = { type = "empty-widget", style = "flib_horizontal_pusher", ignored_by_interaction = true }
    end

    if category == "intermediates" and show_breakdown then
      flow[#flow + 1] = {
        type = "label",
        style = "rcalc_intermediate_breakdown_label",
        caption = {
          "",
          { "gui.rcalc-colored-caption", format_number(output.rate, data.unit ~= nil, false), colors.green },
          " - ",
          { "gui.rcalc-colored-caption", format_number(input.rate, data.unit ~= nil, false), colors.red },
        },
        ignored_by_interaction = true,
      }
    end

    --- @type LocalisedString?
    local suffix
    local unit = data.unit
    if unit then
      suffix = { "si-unit-symbol-" .. unit }
    end

    flow[#flow + 1] = {
      type = "label",
      style = "rcalc_rate_label",
      caption = {
        "gui.rcalc-colored-caption",
        { "", rate_caption, suffix },
        rate_color,
      },
      ignored_by_interaction = true,
    }
    rates_table[#rates_table + 1] = flow
  end

  flib_gui.add(parent, {
    type = "flow",
    direction = "vertical",
    { type = "label", style = "caption_label", caption = { "gui.rcalc-" .. category } },
    rates_table,
  })
end

local unit_lookup = {
  ["rcalc-electric-energy-buffer-dummy"] = "joule",
  ["rcalc-electric-power-dummy"] = "watt",
  ["rcalc-fluid-fuel-dummy"] = "watt",
  ["rcalc-heat-dummy"] = "watt",
  ["rcalc-item-fuel-dummy"] = "watt",
  ["rcalc-thrust-dummy"] = "newton",
}

local gui_rates = {}

--- @param self GuiData
--- @param set CalculationSet
--- @return CategoryDisplayData
function gui_rates.update_display_data(self, set)
  local timescale_data = gui_util.timescale_data[self.selected_timescale]
  local manual_multiplier = self.manual_multiplier
  local multiplier = timescale_data.multiplier or 1
  local divisor, type_filter, divide_stacks, inserter_stack_size = gui_util.get_divisor(self)
  local dictionary = flib_dictionary.get(self.player.index, "search") or {}
  local show_power_input = self.player.mod_settings["rcalc-show-power-consumption"].value --[[@as boolean]]
  local show_pollution = self.player.mod_settings["rcalc-show-pollution"].value --[[@as boolean]]
  local search_query = self.search_query

  --- @param rate Rate
  --- @param is_watts boolean
  --- @return Rate
  local function scale_rate(rate, is_watts)
    local multiplier = is_watts and 1 or multiplier
    local divisor = is_watts and 1 or divisor
    return {
      machine_counts = flib_table.map(rate.machine_counts, function(count)
        return count * manual_multiplier
      end),
      machines = rate.machines * manual_multiplier,
      rate = rate.rate / (divisor or 1) * multiplier * manual_multiplier,
    }
  end

  --- @type table<DisplayCategory, RatesDisplayData[]>
  local category_display_data = {
    products = {},
    intermediates = {},
    ingredients = {},
  }
  --- @type DisplayDataLookup
  local display_data_lookup = {}

  for path, rates in pairs(set.rates) do
    local unit = unit_lookup[rates.name]
    local output = scale_rate(rates.output, unit ~= nil)
    local input = scale_rate(rates.input, unit ~= nil)

    if divide_stacks and rates.type == "item" and not unit then
      local stack_size = prototypes.item[rates.name].stack_size
      output.rate = output.rate / stack_size
      input.rate = input.rate / stack_size
    end

    if inserter_stack_size and inserter_stack_size > 0 and rates.type == "item" and not unit then
      local stack_size = math.min(prototypes.item[rates.name].stack_size, inserter_stack_size)
      output.rate = output.rate / stack_size
      input.rate = input.rate / stack_size
    end

    --- @type DisplayCategory
    local category = "products"
    local sorting_rate = output.rate
    if output.rate > 0 and input.rate > 0 then
      category = "intermediates"
      sorting_rate = output.rate - input.rate
    elseif input.rate > 0 then
      category = "ingredients"
      sorting_rate = input.rate
    end

    if type_filter and (type_filter ~= rates.type or unit or path == "item/rcalc-pollution-dummy/normal") then
      goto continue
    end
    if path == "item/rcalc-electric-power-dummy/normal" and not show_power_input then
      if output.rate > 0 then
        category = "products"
      else
        goto continue
      end
    end
    if path == "item/rcalc-pollution-dummy/normal" and not show_pollution then
      goto continue
    end
    local to_search = string.lower(dictionary[path] or rates.name)
    if not string.find(to_search, search_query, nil, true) then
      goto continue
    end

    --- @type RatesDisplayData
    local data = {
      type = rates.type,
      name = rates.name,
      quality = rates.quality,
      temperature = rates.temperature,
      output = output,
      input = input,
      path = path,
      category = category,
      sorting_rate = sorting_rate,
      completed = set.completed[path] or false,
      unit = unit,
    }
    local category_data = category_display_data[category]
    category_data[#category_data + 1] = data
    display_data_lookup[path] = data

    ::continue::
  end

  for _, rates in pairs(category_display_data) do
    table.sort(rates, function(a, b)
      return a.sorting_rate > b.sorting_rate
    end)
  end

  self.display_data_lookup = display_data_lookup

  return category_display_data
end

--- @param self GuiData
--- @param category_display_data CategoryDisplayData
function gui_rates.update_gui(self, category_display_data)
  local show_checkboxes = self.player.mod_settings["rcalc-show-completion-checkboxes"].value --[[@as boolean]]
  local show_intermediate_breakdowns = self.player.mod_settings["rcalc-show-intermediate-breakdowns"].value --[[@as boolean]]

  local has_ingredients = #category_display_data.ingredients > 0
  local has_intermediates = #category_display_data.intermediates > 0
  local has_products = #category_display_data.products > 0

  local rates_flow = self.elems.rates_flow
  rates_flow.clear()

  if has_ingredients then
    build_rates_table(
      rates_flow,
      "ingredients",
      category_display_data.ingredients,
      not has_intermediates and not has_products,
      show_checkboxes,
      show_intermediate_breakdowns
    )
    if has_intermediates or has_products then
      rates_flow.add({ type = "line", direction = "vertical" })
    end
  end
  if has_intermediates or has_products then
    rates_flow = rates_flow.add({ type = "flow", style = "rcalc_rates_table_vertical_flow", direction = "vertical" })
  end

  if has_products then
    build_rates_table(
      rates_flow,
      "products",
      category_display_data.products,
      true,
      show_checkboxes,
      show_intermediate_breakdowns
    )
    if has_intermediates then
      rates_flow.add({ type = "line", direction = "horizontal" })
    end
  end

  if has_intermediates then
    build_rates_table(
      rates_flow,
      "intermediates",
      category_display_data.intermediates,
      true,
      show_checkboxes,
      show_intermediate_breakdowns
    )
  end

  if not has_ingredients and not has_intermediates and not has_products then
    rates_flow.add({ type = "label", style = "rcalc_machines_label", caption = { "gui.rcalc-no-rates-to-display" } })
  end
end

return gui_rates
