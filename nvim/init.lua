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
require("mark.treesitter")

-- TODO:
-- QuickFix window stuff
-- Project specific settings
--- indent
--- compiler settings
-- Nerdtree replacement
-- Git stuff

-- load old config
--vim.cmd('source old_config.vim')

-- clear whitespace on save
vim.cmd("autocmd BufWritePre * :%s/\\s\\+$//e")

-- No auto insert comments on new line
vim.cmd("autocmd FileType * set formatoptions-=cro")

-- EES project settings
--function SetCSFileSettingsForEES()
--  vim.opt_local.tabstop = 4
--  vim.opt_local.softtabstop = 4
--  vim.opt_local.shiftwidth = 4
--end
--function SetJSFileSettingsForEES()
--  vim.opt_local.tabstop = 2
--  vim.opt_local.softtabstop = 2
--  vim.opt_local.shiftwidth = 2
--end
--if (string.find(vim.fn.getcwd(), "explore%-education%-statistics")) then
--  vim.notify('Settings for EES')
--  --vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
--  --  pattern = "*.cs",
--  --  callback = "SetCSFileSettingsForEES",
--  --})
--  --vim.cmd("autocmd BufRead,BufNewFile cs :call SetCSFileSettingsForEES()")
--  --vim.cmd("autocmd FileType javascript,javascriptreact,typescript,typescriptreact,typescript.tsx :call SetJSFileSettingsForEES()")
--end
