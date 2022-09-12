-- init.lua

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

vim.opt.hidden = true
vim.opt.expandtab = true
vim.opt.mouse = 'a'

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

-- New sp windows open right or bottom
vim.opt.splitbelow = true
vim.opt.splitright = true

-- persistent undo
vim.opt.undodir = '~/.config/nvim/undo'
vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undoreload = 10000

-- make backspace work in insert mode
vim.opt.backspace = { 'indent', 'eol', 'start' }

-- better line wrap
vim.opt.showbreak = '…'

-- highlight stuff
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.api.nvim_set_keymap('n', '<ESC>', ':nohl<CR><ESC>', { silent = true, noremap = true })
vim.cmd(':nohl')

-- case insensitive search, except when using capital letters
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- custom statusline
vim.opt.statusline = '%t' -- file name
--vim.opt.statusline += '%10y' -- type of file, padded 10 spaces
vim.opt.statusline = vim.opt.statusline + '%5m' -- modified marker
vim.opt.statusline = vim.opt.statusline + '%=' -- align right
vim.opt.statusline = vim.opt.statusline + '%-4c' -- column
vim.opt.statusline = vim.opt.statusline + '%l/%L' -- display line / total lines

-- reload files changed outside of nvim
vim.opt.autoread = true

vim.opt.scrolloff = 5

vim.cmd([[ set nobackup ]])
vim.cmd([[ set nowritebackup ]])
--vim.cmd('!mkdir -p ~/.config/nvim/backup', { silent = true })
--vim.opt.backup = true
--vim.opt.backupdir = '~/.config/nvim/backup/'

vim.opt.showcmd = true

vim.opt.showmatch = true
vim.opt.matchpairs = "(:),{:},[:],<:>"
