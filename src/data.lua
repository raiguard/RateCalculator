-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROTOTYPES

local function mipped_icon(name, position, filename, size, mipmap_count, mods)
  local def = {
    type = 'sprite',
    name = name,
    filename = filename,
    position = position,
    size = size or 32,
    mipmap_count = mipmap_count or 2,
    flags = {'icon'}
  }
  if mods then
    for k,v in pairs(mods) do
      def[k] = v
    end
  end
  return def
end

local shortcut_icon = '__RateCalculator__/graphics/shortcut.png'

data:extend{
  -- selection tool
  {
    type = 'selection-tool',
    name = 'rcalc-selection-tool',
    icon = data.raw['selection-tool']['selection-tool'].icon,
    icon_size = data.raw['selection-tool']['selection-tool'].icon_size,
    selection_mode = 'any-entity',
    selection_color = {r=1,g=1,b=0},
    selection_cursor_box_type = 'entity',
    alt_selection_mode = 'any-entity',
    alt_selection_color = {r=1,g=1,b=0},
    alt_selection_cursor_box_type = 'entity',
    stack_size = 1,
    flags = {'hidden', 'only-in-cursor', 'not-stackable'}
  },
  -- shortcut
  {
    type = 'shortcut',
    name = 'rcalc-selection-tool',
    icon = mipped_icon(nil, {0,0}, shortcut_icon, 32, 2),
    disabled_icon = mipped_icon(nil, {48,0}, shortcut_icon, 32, 2),
    small_icon = mipped_icon(nil, {0,32}, shortcut_icon, 24, 2),
    disabled_small_icon = mipped_icon(nil, {36,32}, shortcut_icon, 24, 2),
    action = 'create-blueprint-item',
    item_to_create = 'rcalc-selection-tool'
  }
}