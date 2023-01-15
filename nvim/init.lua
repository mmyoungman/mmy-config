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

function Build(buildCmd, errorformat)
  local quickfixfileCmd = string.format("silent !%s &> quickfixfile", buildCmd)

  -- for debugging
  --print(quickfixCmd)
  --vim.cmd("!cat quickfixfile")

  vim.cmd(quickfixfileCmd)

  vim.opt.errorformat = errorformat
  vim.cmd("silent cfile quickfixfile")
  vim.cmd("silent !rm quickfixfile")

  if vim.tbl_isempty(vim.fn.getqflist()) then
    vim.cmd("cclose")
    vim.notify("Build successful")
  else
    vim.cmd("copen")
  end
end

function Run(runCmd, errorformat)
  local runOutputFileCmd = string.format("silent !%s &> runOutputFile", runCmd)

  -- for debugging
  --print(runOutputFileCmd)
  --vim.cmd("!cat runOutputFile")

  vim.cmd(runOutputFileCmd)

  if(errorformat ~= nil)
  then
    vim.opt.errorformat = errorformat
    vim.cmd("silent cfile runOutputFile")
    vim.cmd("silent !rm runOutputFile")

    if vim.tbl_isempty(vim.fn.getqflist()) then
      vim.cmd("cclose")
    else
      vim.cmd("copen")
    end
  end
end

vim.api.nvim_create_user_command('EyestrBuild', function()
  local buildCmd = "./scripts/build.sh"
  local errorformat = "%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m,%-G%.%#"
  Build(buildCmd, errorformat)
end, {})

vim.api.nvim_create_user_command('EyestrRun', function()
  Run("./scripts/run.sh", "[%tRROR] (%f:%l) %m,[D%tBUG] (%f:%l) %m,%-G%.%#")
end, {})

vim.api.nvim_set_keymap("n", "<F9>", ":EyestrBuild<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<F12>", ":EyestrRun<CR>", { noremap = true })

vim.api.nvim_create_user_command('EESBuild', function()
  local buildCmd = "dotnet build /nologo /v:q /property:GenerateFullPaths=true src/GovUk.Education.ExploreEducationStatistics.sln"
  local errorformat = "%f(%l\\,%c): %trror %m,%-G%.%#"
  Build(buildCmd, errorformat)
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
