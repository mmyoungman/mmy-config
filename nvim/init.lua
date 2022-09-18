-- init.lua
require "mark.plugins"
require "mark.options"
require "mark.keymaps"
require "mark.colorscheme"

-- load old config
--vim.cmd('source old_config.vim')

-- clear whitespace on save
vim.cmd("autocmd BufWritePre * :%s/\\s\\+$//e")

-- No auto insert comments on new line
vim.cmd("autocmd FileType * set formatoptions-=cro")
