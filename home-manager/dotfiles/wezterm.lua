-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

local function is_mac()
	return wezterm.target_triple:find("darwin") ~= nil
end

config.term = "xterm-256color"
config.unicode_version = 14
config.adjust_window_size_when_changing_font_size = false

if not is_mac() then
	config.enable_wayland = true
end

config.front_end = "WebGpu"

config.default_prog = { "fish" }

config.line_height = 1.1
config.use_dead_keys = false
config.colors = {
	cursor_fg = "black",
}

-- `theme` is a global set by the Nix-generated wezterm.lua; nil when loaded on its own.
if theme then
	-- The active tab is a lighter neutral (selection background); the rest of the bar sits one step darker.
	config.colors.tab_bar = {
		background = theme.DARKER_BACKGROUND,
		inactive_tab_edge = theme.EDGE,
		active_tab = { bg_color = theme.SELECTION, fg_color = theme.TEXT, intensity = "Bold" },
		inactive_tab = { bg_color = theme.DARKER_BACKGROUND, fg_color = theme.TEXT_ALT },
		inactive_tab_hover = { bg_color = theme.SURFACE, fg_color = theme.TEXT },
		new_tab = { bg_color = theme.DARKER_BACKGROUND, fg_color = theme.TEXT_ALT },
		new_tab_hover = { bg_color = theme.SURFACE, fg_color = theme.TEXT },
	}
end
config.window_close_confirmation = "NeverPrompt"
config.window_background_opacity = 0.5
config.window_padding = { left = 18, right = 18, top = 6, bottom = 6 }
config.use_fancy_tab_bar = false
config.tab_max_width = 1000

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s)
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

local function fmt_working_dir(s)
	-- clean up leftover front slash if it exists
	s = string.gsub(s.file_path, "^/", "")
	local fmt_profile = string.gsub(wezterm.home_dir, "\\", "/")
	s = string.gsub(s, fmt_profile, "~")
	-- TODO: find a better way to format home directory if we're on NixOS
	s = string.gsub(s, "home/andy", "~")
	-- TODO: find a better way to format home directory if we're on MacOS
	s = string.gsub(s, "Users/andybolton", "~")
	return s
end

local tab_title = function(tab_info)
	if not tab_info.active_pane.current_working_dir then
		return "no working dir"
	end

	local baseexe = basename(tab_info.active_pane.foreground_process_name)
	local fmt_dir = fmt_working_dir(tab_info.active_pane.current_working_dir)
	return baseexe .. " @ " .. fmt_dir
end

if is_mac() then
	config.initial_rows = 30
	config.initial_cols = 100

	config.window_decorations = "RESIZE"
else
	config.window_decorations = "NONE"
end

wezterm.on("format-tab-title", function(tab, tabs)
	local mux_window = wezterm.mux.get_window(tab.window_id)
	local mux_tab = mux_window:active_tab()
	local mux_tab_cols = mux_tab:get_size().cols

	local tab_count = #tabs
	local inactive_tab_cols = math.floor(mux_tab_cols / tab_count)
	local active_tab_cols = mux_tab_cols - (tab_count - 1) * inactive_tab_cols

	local title = tab_title(tab)
	title = " " .. title .. " "
	local title_cols = wezterm.column_width(title)
	local icon = "😊"

	-- Divide into 3 areas and center the title
	if tab.is_active then
		local rest_cols = math.max(active_tab_cols - title_cols - wezterm.column_width(icon), 0)
		local right_cols = math.ceil(rest_cols / 2)
		local left_cols = rest_cols - right_cols
		return {
			-- left
			{ Text = wezterm.pad_right("", left_cols) },
			-- center
			{ Text = icon },
			{ Foreground = theme and { Color = theme.CYAN } or { AnsiColor = "Aqua" } },
			{ Attribute = { Italic = true } },
			{ Text = title },
			-- right
			{ Text = wezterm.pad_right("", right_cols) },
		}
	else
		local rest_cols = math.max(inactive_tab_cols - title_cols, 0)
		local right_cols = math.ceil(rest_cols / 2)
		local left_cols = rest_cols - right_cols
		return {
			-- left
			{ Text = wezterm.pad_right("", left_cols) },
			-- center
			{ Attribute = { Italic = true } },
			{ Text = title },
			-- right
			{ Text = wezterm.pad_right("", right_cols) },
		}
	end
end)

config.leader = { key = " ", mods = "ALT" }
config.keys = {
	{ key = "F", mods = "CTRL|SHIFT", action = act.Search("CurrentSelectionOrEmptyString") },
	{ key = "8", mods = "CTRL", action = act.PaneSelect },
	{
		key = "h",
		mods = "ALT|CTRL",
		action = act.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "j",
		mods = "ALT|CTRL",
		action = act.AdjustPaneSize({ "Down", 5 }),
	},
	{ key = "k", mods = "ALT|CTRL", action = act.AdjustPaneSize({ "Up", 5 }) },
	{
		key = "l",
		mods = "ALT|CTRL",
		action = act.AdjustPaneSize({ "Right", 5 }),
	},
	{
		key = "h",
		mods = "ALT|SHIFT",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "l",
		mods = "ALT|SHIFT",
		action = act.ActivatePaneDirection("Right"),
	},
	{
		key = "k",
		mods = "ALT|SHIFT",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "j",
		mods = "ALT|SHIFT",
		action = act.ActivatePaneDirection("Down"),
	},
	{
		key = "w",
		mods = "ALT",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	-- Remap debug overlay
	{ key = "d", mods = "LEADER", action = wezterm.action.ShowDebugOverlay },
	{
		key = "h",
		mods = "LEADER",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "v",
		mods = "LEADER",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{ key = "V", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	{
		key = "Enter",
		mods = "ALT",
		action = wezterm.action.DisableDefaultAssignment,
	},
	{
		key = "N",
		mods = "CTRL",
		action = wezterm.action.DisableDefaultAssignment,
	},
	{
		key = "n",
		mods = "CMD",
		action = wezterm.action.DisableDefaultAssignment,
	},
	{
		key = "n",
		mods = "CMD",
		action = wezterm.action.DisableDefaultAssignment,
	},
}

require("modal").apply_to_config(config)

return config
