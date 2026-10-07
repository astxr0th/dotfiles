local opt = vim.opt
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
opt.number = true
opt.relativenumber = true

opt.cursorline = true
opt.termguicolors = true
opt.winborder = "rounded"
opt.signcolumn = "yes"
vim.lsp.inlay_hint.enable = true
opt.tabstop = 8
vim.opt.expandtab = true
vim.g.tinted_background_transparent = 1

opt.shiftwidth = 8
vim.diagnostic.config({
	virtual_text = {
		spacing = 4,
		source = true,
	},
})
require("config.lazy")
require("config.keymaps")
local default_theme = "base16-oceanicnext"

local function get_tinty_theme()
	local theme_name = vim.fn.system("cat ~/.local/share/tinted-theming/tinty/current_scheme")

	if vim.v.shell_error ~= 0 then
		return default_theme
	else
		return vim.trim(theme_name)
	end
end

local function handle_focus_gained()
	local new_theme_name = get_tinty_theme()
	local current_theme_name = vim.g.colors_name

	if current_theme_name ~= new_theme_name then
		vim.cmd("colorscheme " .. new_theme_name)
		require("lualine").setup()
	end
	require("lualine").setup()
end

local function main()
	vim.o.termguicolors = true
	vim.g.tinted_colorspace = 256
	local current_theme_name = get_tinty_theme()

	vim.cmd("colorscheme " .. current_theme_name)

	vim.api.nvim_create_autocmd("FocusGained", {
		callback = handle_focus_gained,
	})
end

main()
