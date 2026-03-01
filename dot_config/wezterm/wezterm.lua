-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- opacity and background blur
config.window_background_opacity = 0.9
config.macos_window_background_blur = 5
-- for kde and windows equivalents of a blur, use
-- config.win32_system_backdrop
-- config.kde_window_background_blur = true

-- prompt when closing windows (not tab)
config.window_close_confirmation = "AlwaysPrompt"
-- config.window_close_confirmation = "NeverPrompt"

-- Hotkeys
-- https://wezterm.org/config/keys.html
config.keys = {
	-- CMD+W already does CloseCurrentTab by default,
	-- we just want to disable confirming this
	{
		key = "w",
		mods = "CMD",
		action = wezterm.action.CloseCurrentTab({ confirm = false }),
	},
	-- map hotkey for moving tabs similar to iTerm
	{
		key = "LeftArrow",
		mods = "CMD|SHIFT",
		action = wezterm.action.MoveTabRelative(-1),
	},
	{
		key = "RightArrow",
		mods = "CMD|SHIFT",
		action = wezterm.action.MoveTabRelative(1),
	},
}

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size
config.font_size = 10

-- or changing font family + attributes
-- See: https://wezterm.org/config/lua/wezterm/font.html?h=weight
config.font = wezterm.font("JetBrains Mono", { weight = "ExtraBold" })
-- config.font = weztekm.font("Agave Nerd Font Mono")
-- config.font = wezterm.font("Lekton Nerd Font Mono")
-- config.font = wezterm.font("MesloLGS NF")
-- config.font = wezterm.font("MesloLGS Nerd Font Mono")
--
-- P.S. You don't need to install nerd fonts in Wezterm,
-- because for other fonts, there's a default font fallback
-- https://wezterm.org/confpig/lua/wezterm/nerdfonts.html

-- or, changing the color scheme
-- Reference:
-- https://wezterm.org/config/lua/config/color_schemes.html
-- config.color_scheme = "Catppuccin Mocha"
-- config.color_scheme = "Catppuccin Latte"
-- config.color_scheme = "Solarized Dark (Gogh)"
-- config.color_scheme = "Solarized Dark Higher Contrast"
config.color_scheme = "Tango Dark"
-- config.color_scheme = "Tokyo Night Moon"
-- config.color_scheme = "Tokyo Night"
--
-- for a complete list of color_schemes, see:
-- https://github.com/wezterm/wezterm/blob/main/config/src/scheme_data.rs

-- Finally, return the configuration to wezterm:
return config
