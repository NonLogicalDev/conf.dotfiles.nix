local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

-- Match the active iTerm2 Default profile's colors and interaction model.
config.font_dirs = { wezterm.home_dir .. '/Library/Fonts' }
config.font = wezterm.font('JetBrainsMono Nerd Font Mono')
config.font_size = 13

config.initial_cols = 120
config.initial_rows = 32
config.window_padding = {
  left = 2,
  right = 2,
  top = 2,
  bottom = 2,
}
config.window_background_opacity = 1
config.macos_window_background_blur = 0
config.window_decorations = 'TITLE | RESIZE | MACOS_FORCE_ENABLE_SHADOW'
config.native_macos_fullscreen_mode = true

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32
config.status_update_interval = 250
config.command_palette_font_size = 13
config.command_palette_rows = 12
config.command_palette_bg_color = '#20252c'
config.command_palette_fg_color = '#dcdcdc'
config.colors = {
  foreground = '#dcdcdc',
  background = '#15191f',
  cursor_bg = '#ffffff',
  cursor_fg = '#c9c9c9',
  cursor_border = '#ffffff',
  selection_fg = '#000000',
  selection_bg = '#b3d7ff',
  scrollbar_thumb = '#686868',
  split = '#686868',
  ansi = {
    '#010202',
    '#b43c2a',
    '#00c200',
    '#c7c400',
    '#92b6ff',
    '#c040be',
    '#35c5d7',
    '#c7c7c7',
  },
  brights = {
    '#686868',
    '#dd7975',
    '#58e790',
    '#ece100',
    '#a7abf2',
    '#e17ee1',
    '#60fdff',
    '#ffffff',
  },
  tab_bar = {
    background = '#15191f',
    active_tab = {
      bg_color = '#30363d',
      fg_color = '#ffffff',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#15191f',
      fg_color = '#8b949e',
    },
    inactive_tab_hover = {
      bg_color = '#252b33',
      fg_color = '#dcdcdc',
    },
  },
}

config.scrollback_lines = 100000
config.enable_scroll_bar = true
config.bold_brightens_ansi_colors = true
config.default_cursor_style = 'SteadyBlock'
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true
config.adjust_window_size_when_changing_font_size = false
config.audible_bell = 'Disabled'
config.hide_mouse_cursor_when_typing = true
config.inactive_pane_hsb = {
  saturation = 0.85,
  brightness = 0.7,
}

config.keys = {
  -- Codex inserts a newline for Ctrl+J. Send the same LF byte so that
  -- Shift+Enter remains distinct from Enter even without a keyboard protocol.
  { key = 'Enter', mods = 'SHIFT', action = act.SendString '\x0a' },
  { key = 'UpArrow', mods = 'SHIFT', action = act.ScrollToPrompt(-1) },
  { key = 'DownArrow', mods = 'SHIFT', action = act.ScrollToPrompt(1) },
  { key = 'UpArrow', mods = 'SHIFT|SUPER', action = act.ScrollToPrompt(-1) },
  { key = 'DownArrow', mods = 'SHIFT|SUPER', action = act.ScrollToPrompt(1) },
  { key = 'd', mods = 'SUPER', action = act.SplitPane { direction = 'Right' } },
  { key = 'd', mods = 'SHIFT|SUPER', action = act.SplitPane { direction = 'Down' } },
  { key = 'w', mods = 'SUPER', action = act.CloseCurrentPane { confirm = true } },
  { key = 'Enter', mods = 'SUPER', action = act.ToggleFullScreen },
  { key = 'Enter', mods = 'SHIFT|SUPER', action = act.TogglePaneZoomState },
  { key = '[', mods = 'SUPER', action = act.ActivatePaneDirection 'Prev' },
  { key = ']', mods = 'SUPER', action = act.ActivatePaneDirection 'Next' },
  { key = 'LeftArrow', mods = 'ALT', action = act.SendKey { key = 'b', mods = 'ALT' } },
  { key = 'RightArrow', mods = 'ALT', action = act.SendKey { key = 'f', mods = 'ALT' } },
  { key = 'LeftArrow', mods = 'ALT|SUPER', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT|SUPER', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'ALT|SUPER', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'ALT|SUPER', action = act.ActivatePaneDirection 'Down' },
  { key = 'LeftArrow', mods = 'CTRL|SUPER', action = act.AdjustPaneSize { 'Left', 2 } },
  { key = 'RightArrow', mods = 'CTRL|SUPER', action = act.AdjustPaneSize { 'Right', 2 } },
  { key = 'UpArrow', mods = 'CTRL|SUPER', action = act.AdjustPaneSize { 'Up', 1 } },
  { key = 'DownArrow', mods = 'CTRL|SUPER', action = act.AdjustPaneSize { 'Down', 1 } },
  { key = 'c', mods = 'SHIFT|SUPER', action = act.ActivateCopyMode },
  { key = 'phys:Space', mods = 'SHIFT|SUPER', action = act.QuickSelect },
  { key = 'p', mods = 'SHIFT|SUPER', action = act.ActivateCommandPalette },
  {
    key = 'o',
    mods = 'SUPER',
    action = act.ShowLauncherArgs {
      flags = 'FUZZY|TABS|LAUNCH_MENU_ITEMS|DOMAINS|WORKSPACES|COMMANDS',
    },
  },
  {
    key = 'e',
    mods = 'ALT|SUPER',
    action = act.ShowLauncherArgs {
      flags = 'FUZZY|TABS|WORKSPACES',
    },
  },
}

config.ssh_domains = wezterm.default_ssh_domains()

local override = os.getenv 'WEZTERM_REMOTE_PATH'
local override_domain = os.getenv 'WEZTERM_REMOTE_DOMAIN' or __DOTFILES_DEFAULT_REMOTE_DOMAIN__

if override and override ~= '' and override_domain and override_domain ~= '' then
  for _, domain in ipairs(config.ssh_domains) do
    if domain.name == override_domain then
      domain.remote_wezterm_path = override
    end
  end
end

-- Keep the classic bottom tab row visible as a compact Zellij-style helper
-- bar. WezTerm clips the left side of the right status first, so the most useful
-- Close and Zoom hints stay visible in narrower windows.
local function append_shortcut_hint(elements, key, label)
  table.insert(elements, { Background = { Color = '#30363d' } })
  table.insert(elements, { Foreground = { Color = '#ffffff' } })
  table.insert(elements, { Attribute = { Intensity = 'Bold' } })
  table.insert(elements, { Text = ' ' .. key .. ' ' })
  table.insert(elements, { Background = { Color = '#15191f' } })
  table.insert(elements, { Foreground = { Color = '#8b949e' } })
  table.insert(elements, { Attribute = { Intensity = 'Normal' } })
  table.insert(elements, { Text = ' ' .. label .. '  ' })
end

local function format_shortcut_hints(hints)
  local elements = {}
  for _, hint in ipairs(hints) do
    append_shortcut_hint(elements, hint[1], hint[2])
  end
  return wezterm.format(elements)
end

local shortcut_helper_bars = {
  normal = format_shortcut_hints {
    { '⌘O', 'Actions' },
    { '⌘D', 'Split' },
    { '⇧⌘D', 'Split Down' },
    { '⇧⌘↵', 'Zoom' },
    { '⌘W', 'Close' },
  },
  leader = format_shortcut_hints {
    { 'LEADER', 'Next Key' },
    { 'Esc', 'Cancel' },
  },
  copy_mode = format_shortcut_hints {
    { 'h/j/k/l', 'Move' },
    { 'Space', 'Select' },
    { '⌘F', 'Search' },
    { 'y', 'Copy' },
    { 'Esc', 'Exit' },
  },
  search_mode = format_shortcut_hints {
    { '↑/↓', 'Match' },
    { '⌃N/⌃P', 'Next/Prev' },
    { '⌃R', 'Search Type' },
    { '⌃U', 'Clear' },
    { 'Esc', 'Exit' },
  },
  command_palette = format_shortcut_hints {
    { 'Type', 'Filter' },
    { '↑/↓', 'Move' },
    { '⌃U', 'Clear' },
    { '↵', 'Run' },
    { 'Esc', 'Exit' },
  },
  tab_navigator_stock = format_shortcut_hints {
    { 'j/k', 'Move' },
    { '/', 'Filter' },
    { '↵', 'Open' },
    { 'Esc', 'Exit' },
  },
  tab_navigator_dev = format_shortcut_hints {
    { 'j/k', 'Move' },
    { '/', 'Filter' },
    { '↵', 'Open' },
    { '⌃D', 'Close Tab' },
    { 'Esc', 'Exit' },
  },
}

wezterm.on('update-status', function(window, pane)
  local helper_bar = shortcut_helper_bars.normal
  local ok, ui_context = pcall(function()
    return window:active_ui_context()
  end)
  if not ok then
    ui_context = nil
  end

  if ui_context == 'command_palette' then
    helper_bar = shortcut_helper_bars.command_palette
  elseif window:leader_is_active() then
    helper_bar = shortcut_helper_bars.leader
  else
    local key_table = window:active_key_table()
    if key_table == 'copy_mode' then
      helper_bar = shortcut_helper_bars.copy_mode
    elseif key_table == 'search_mode' then
      helper_bar = shortcut_helper_bars.search_mode
    elseif pane:tab() == nil and pane:get_title() == 'Tab Navigator' then
      -- Tab Navigator is a GUI overlay rather than a named key table. Requiring
      -- both its built-in title and the overlay-only nil tab avoids matching a
      -- regular terminal pane that happens to use the same title.
      helper_bar = ok and shortcut_helper_bars.tab_navigator_dev
        or shortcut_helper_bars.tab_navigator_stock
    end
  end

  window:set_right_status(helper_bar)
end)

return config
