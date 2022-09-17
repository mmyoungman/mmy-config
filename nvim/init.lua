-- init.lua
require "mark.options"

-- load old config
vim.cmd('source old_config.vim')

vim.fn['plug#begin']('~/.config/nvim/plugged')
--vim.cmd [[Plug 'neoclide/coc.nvim', {'branch': 'release'}]]
vim.cmd [[Plug 'scrooloose/nerdtree']]
vim.cmd [[Plug 'easymotion/vim-easymotion']]
vim.cmd [[Plug 'junegunn/fzf', { 'do':'./install --all' }]]
vim.cmd [[Plug 'junegunn/fzf.vim']]
--vim.cmd [[Plug 'HerringtonDarkholme/yats.vim']] -- TS highlighting
--vim.cmd [[Plug 'andreyorst/SimpleClangFormat.vim']]
vim.fn['plug#end']()

vim.g.mapleader = '\\'
vim.g.maplocalleader = '\\' 

vim.cmd('colorscheme desert')
vim.cmd('syntax on')

-- switch to a different buffer
vim.api.nvim_set_keymap('n', '<leader>b', ':Buffers<CR>', { noremap = true })

-- quick way to open and load init.lua
vim.api.nvim_set_keymap('n', '<leader>ev', ':edit $MYVIMRC<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>sv', ':write<CR>:source $MYVIMRC<CR>', { noremap = true })

-- convenient cursor movement
vim.api.nvim_set_keymap('n', '<C-k>', '{', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-j>', '}', { noremap = true })
vim.api.nvim_set_keymap('v', '<C-k>', '{', { noremap = true })
vim.api.nvim_set_keymap('v', '<C-j>', '}', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-h>', '^', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-l>', '$', { noremap = true })

-- Since insert mode C-h is backspace, C-l should delete char infront
vim.api.nvim_set_keymap('i', '<C-l>', '<del>', { noremap = true })

-- Surround word with " or < or (
vim.api.nvim_set_keymap('n', '<leader>"', 'viw<esc>a"<esc>hbi"<esc>lel', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>\'', 'viw<esc>a\'<esc>hbi\'<esc>lel', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader><', 'viw<esc>a><esc>hbi<<esc>lel', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>(', 'viw<esc>a)<esc>hbi(<esc>lel', { noremap = true })
--Test: flkjal alfkjalf lajslkf

-- copy to end of line, to match behaviour of D and C
vim.api.nvim_set_keymap('n', 'Y', 'y$', { noremap = true })

-- copy and paste to system clipboard
vim.api.nvim_set_keymap('v', '<leader>y', '"+y', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>p', '"+p', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>P', '"+P', { noremap = true })

vim.api.nvim_set_keymap('n', '<ESC>', ':nohl<CR><ESC>', { silent = true, noremap = true })

vim.cmd([[ set nobackup ]])
vim.cmd([[ set nowritebackup ]])
--vim.cmd('!mkdir -p ~/.config/nvim/backup', { silent = true })
--vim.opt.backup = true
--vim.opt.backupdir = '~/.config/nvim/backup/'
