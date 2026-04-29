-- Module for toggling between 2 colorschemes
-- Inpsired by https://www.sebastian-hans.de/blog/color-scheme-switching-for-wezterm/
-- (but converted into lua module)
local wezterm = require("wezterm")
local module = {}
local home = os.getenv("HOME")

local color_scheme_file = home .. "/.color-scheme"

-- Reference:
-- https://wezterm.org/config/lua/config/color_schemes.html
-- "Catppuccin Latte" "Catppuccin Macchiato" "Catppuccin Mocha"
-- "Solarized Dark (Gogh)" "Solarized Dark Higher Contrast"
-- "Tango Dark"
-- "Tokyo Night Moon" "Tokyo Night"
-- "Vacuous 2 (terminal.sexy)"
local default_color_scheme = "FunForrest"
local alternate_color_scheme = "Builtin Solarized Light"

local function load_color_scheme()
	local color_scheme = default_color_scheme
	local file = io.open(color_scheme_file, "r")
	if file then
		for line in file:lines() do
			if not line:match("^%s*#") then -- Also skips lines with leading spaces before #
				color_scheme = line
				break
			end
		end
		file:close()
	end
	return color_scheme
end

local function save_color_scheme(color_scheme)
	local file = io.open(color_scheme_file, "w+")
	if file then
		file:write(color_scheme)
		file:flush()
		file:close()
	end
	return color_scheme
end

function module.apply_to_config(config)
	config.color_scheme = load_color_scheme()

	config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 }
	config.keys = {
		{
			key = "c",
			mods = "LEADER|CTRL",
			action = wezterm.action.Multiple({
				wezterm.action.EmitEvent("toggle-color-scheme"),
				wezterm.action.ReloadConfiguration,
			}),
		},
	}
end

wezterm.on("toggle-color-scheme", function(_window, _pane)
	local color_scheme = load_color_scheme()
	local new_color_scheme = default_color_scheme
	if color_scheme == default_color_scheme then
		new_color_scheme = alternate_color_scheme
	end
	save_color_scheme(new_color_scheme)
end)

return module
