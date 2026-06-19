return {
  -- nvzone right-click / action menu (standalone, was pulled in by NvChad).
  -- Loaded on demand by the menu mappings in mappings.lua.
  {
    'nvzone/menu',
    dependencies = { 'nvzone/volt' },
    lazy = true,
  },
  -- minty color picker: :Huefy / :Shades and the menu's "Color Picker" action
  {
    'nvzone/minty',
    cmd = { 'Huefy', 'Shades' },
  },
}
