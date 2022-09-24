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

vim.api.nvim_create_user_command('DotnetBuild', function()
  --vim.cmd("write %")
  --local winnr = vim.fn.win_getid()
  --local bufnr = vim.api.nvim_win_get_buf(winnr)

  --vim.opt.errorformat = "%f(%l\\,%c): %tarning %m,%f(%l\\,%c): %trror %m,%-G%.%#"
  vim.opt.errorformat = "%f(%l\\,%c): %trror %m,%-G%.%#"
  vim.cmd("!dotnet build /nologo /v:q /property:GenerateFullPaths=true src/GovUk.Education.ExploreEducationStatistics.sln | sort -u > quickfixfile")

  vim.cmd("cfile quickfixfile")
  vim.cmd("!rm quickfixfile")

  if vim.tbl_isempty(vim.fn.getqflist()) then
    vim.notify("Build successful")
  else
    vim.cmd("copen")
    vim.cmd("wincmd J")
  end
end, {})

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
