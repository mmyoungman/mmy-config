-- init.lua
-- NOTE: first print / vim.notify is ignored, so
-- this so errors appear on nvim startup
vim.notify('--')

require("mark.plugins")
require("mark.options")
require("mark.keymaps")
require("mark.colorscheme")
require("mark.completion")
require("mark.lsp")
require("mark.telescope")

-- load old config
--vim.cmd('source old_config.vim')

-- clear whitespace on save
vim.cmd("autocmd BufWritePre * :%s/\\s\\+$//e")

-- No auto insert comments on new line
vim.cmd("autocmd FileType * set formatoptions-=cro")
