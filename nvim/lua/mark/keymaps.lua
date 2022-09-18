local keymap = vim.api.nvim_set_keymap
local noremap = { noremap = true }

vim.g.mapleader = '\\'
vim.g.maplocalleader = '\\' 

-- remove highlight when pressing esc
keymap('n', '<ESC>', ':nohl<CR><ESC>', { silent = true, noremap = true })

-- file navigation
keymap('n', '<leader>e', ':Lex 30<CR>', noremap)

-- switch to a different buffer
--keymap('n', '<leader>b', ':buffers<CR>', noremap)
keymap('n', '<S-l>', ':bnext<CR>', noremap)
keymap('n', '<S-h>', ':bprev<CR>', noremap)

-- quick way reload lua config files
keymap('n', '<leader>sv', ':write<CR>:luafile %<CR>', noremap)

-- convenient cursor movement
keymap('n', '<C-k>', '{', noremap)
keymap('n', '<C-j>', '}', noremap)
keymap('v', '<C-k>', '{', noremap)
keymap('v', '<C-j>', '}', noremap)
keymap('n', '<C-h>', '^', noremap)
keymap('n', '<C-l>', '$', noremap)
keymap('v', '<C-h>', '^', noremap)
keymap('v', '<C-l>', '$', noremap)

-- Since insert mode C-h is backspace, C-l should delete char infront
keymap('i', '<C-l>', '<del>', noremap)

-- Surround word with " or < or (
keymap('n', '<leader>"', 'viw<esc>a"<esc>hbi"<esc>lel', noremap)
keymap('n', '<leader>\'', 'viw<esc>a\'<esc>hbi\'<esc>lel', noremap)
keymap('n', '<leader><', 'viw<esc>a><esc>hbi<<esc>lel', noremap)
keymap('n', '<leader>(', 'viw<esc>a)<esc>hbi(<esc>lel', noremap)
--Test: flkjal alfkjalf lajslkf

-- copy to end of line, to match behaviour of D and C
keymap('n', 'Y', 'y$', noremap)

-- copy and paste to system clipboard
keymap('v', '<leader>y', '"+y', noremap)
keymap('n', '<leader>p', '"+p', noremap)
keymap('n', '<leader>P', '"+P', noremap)

-- Resize split with arrows
keymap("n", "<C-Up>", ":resize +2<CR>", noremap)
keymap("n", "<C-Down>", ":resize -2<CR>", noremap)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", noremap)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", noremap)

-- indent
keymap("v", "<", "<gv", noremap)
keymap("v", ">", ">gv", noremap)

-- keep clipboard when pasting over visual selection
keymap("v", "p", '"_dP', noremap) 