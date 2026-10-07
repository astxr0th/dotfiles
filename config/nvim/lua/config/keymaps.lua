local map = vim.keymap.set

map("n", "<leader>ff", function()
	Snacks.picker.files()
end)
map("n", "<leader>lg", function()
	Snacks.picker.grep()
end)

-- lsp keybinds
map("n", "K", "<cmd> Lspsaga hover_doc<cr>")
map("n", "go", "<cmd> Lspsaga goto_definition<cr>")
map("n", "gr", "<cmd> Lspsaga finder<cr>")
map("n", "<leader>qf", "<cmd> Lspsaga code_action<cr>")
map("n", "<C-f>", function()
	vim.lsp.buf.format()
end)
-- bufferline keybinds
map("n", "<A-1>", "<cmd> BufferLineGoToBuffer 1 <cr>")
map("n", "<A-2>", "<cmd> BufferLineGoToBuffer 2 <cr>")
map("n", "<A-3>", "<cmd> BufferLineGoToBuffer 3 <cr>")
map("n", "<A-4>", "<cmd> BufferLineGoToBuffer 4 <cr>")
map("n", "<A-5>", "<cmd> BufferLineGoToBuffer 5 <cr>")
map("n", "<A-6>", "<cmd> BufferLineGoToBuffer 6 <cr>")
map("n", "<A-7>", "<cmd> BufferLineGoToBuffer 7 <cr>")
map("n", "<A-8>", "<cmd> BufferLineGoToBuffer 8 <cr>")
map("n", "<A-9>", "<cmd> BufferLineGoToBuffer 9 <cr>")
map("n", "<A-0>", "<cmd> BufferLineGoToBuffer last <cr>")
map("n", "<leader>w", "<cmd> bdelete! <cr>")

-- util keybinds
map("n", "<leader>t", "<cmd> terminal <cr>")
map("n", "<A-t>", "<cmd>Lspsaga term_toggle<cr>")
map("t", "<esc>", "<c-\\><c-n>")
map("n", "<A-e>", "<cmd>NvimTreeToggle<cr>")
map("n", "<C-c>", "<cmd> vim.b.completion != vim.b.completion <cr>")
