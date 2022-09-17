-- init.lua
require "mark.options"
require "mark.keymaps"

-- load old config
--vim.cmd('source old_config.vim')
--
--vim.fn['plug#begin']('~/.config/nvim/plugged')
----vim.cmd [[Plug 'neoclide/coc.nvim', {'branch': 'release'}]]
--vim.cmd [[Plug 'scrooloose/nerdtree']]
--vim.cmd [[Plug 'easymotion/vim-easymotion']]
--vim.cmd [[Plug 'junegunn/fzf', { 'do':'./install --all' }]]
--vim.cmd [[Plug 'junegunn/fzf.vim']]
----vim.cmd [[Plug 'HerringtonDarkholme/yats.vim']] -- TS highlighting
----vim.cmd [[Plug 'andreyorst/SimpleClangFormat.vim']]
--vim.fn['plug#end']()

vim.cmd('colorscheme desert')
vim.cmd('syntax on')

vim.cmd("autocmd BufWritePre * :%s/\\s\\+$//e")
