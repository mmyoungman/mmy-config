-- init.lua
require "mark.plugins"
require "mark.options"
require "mark.keymaps"

-- load old config
--vim.cmd('source old_config.vim')
--
vim.cmd('colorscheme desert')
vim.cmd('syntax on')

-- clear whitespace on save
vim.cmd("autocmd BufWritePre * :%s/\\s\\+$//e")
