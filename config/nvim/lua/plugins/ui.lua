return {
	{
		"vyfor/cord.nvim",
		---@type CordConfig
		opts = {
			display = {
				theme = "atom",
			},
			editor = { tooltip = "ur gay x3" },
		},
	},
	{
		"tinted-theming/tinted-vim",
		lazy = false,
		priority = 1000,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		---@module "ibl"
		---@type ibl.config
		opts = {
			scope = { enabled = true },
		},
	},

	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", "RRethy/base16-nvim" },
		opts = {
			options = {
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "diagnostics" },
				lualine_c = { "filename", "branch", "navic" },
				lualine_x = { "lsp_status", "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		},
	},

	{
		"nvim-treesitter/nvim-treesitter",
		opts = { install_dir = vim.fn.stdpath("data") .. "/site" },
		lazy = false,
		build = ":TSUpdate",
	},
	{
		"nvimdev/lspsaga.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter", -- for syntax highlighting inside the popup
		},
		opts = {
			symbol_in_winbar = { enable = true },
			lightbulb = {
				enable = true,
				sign = false,
			},
			hover = {
				max_width = 0.6,
				open_link = "gx",
				open_browser = "!google-chrome",
			},
		},
	},
	{
		"akinsho/bufferline.nvim",
		opts = {},
	},
}
