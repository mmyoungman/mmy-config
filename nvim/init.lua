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
