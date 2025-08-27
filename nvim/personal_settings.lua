vim = vim -- get rid of warnings

if vim.fn.executable('rg') == 0 then -- for telescope plugin live_grep
  print("Ripgrep not installed! Telescope live_grep won't work!")
end

vim.g.mapleader = '\\'
vim.g.maplocalleader = '\\'

vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Clear whitespace before save',
  pattern = '*',
  command = ':%s/\\s\\+$//e'
})

vim.api.nvim_create_autocmd({'CursorHold','FocusLost'}, {
  desc = 'Autosave changes',
  pattern = '*',
  callback = function()
    vim.cmd('silent! wall')
  end
})

vim.api.nvim_create_autocmd('FileType', {
  desc = 'No auto insert comments on new line',
  pattern = '*',
  command = 'set formatoptions-=cro'
})

vim.keymap.set('n', '<C-h>', '^', { noremap = true })
vim.keymap.set('n', '<C-l>', '$', { noremap = true })
vim.keymap.set('v', '<C-h>', '^', { noremap = true })
vim.keymap.set('v', '<C-l>', '$', { noremap = true })

-- quickfix
--function QuickFixOpen()
--  -- quickfix_is_open = vim.fn.winsaveview()
--  -- currentWindow = vim.api.nvim_get_current_win()
--  -- vim.fn.copen
--  -- TODO: execute currentWindow . "wincmd w" thingy here
--  -- vim.fn.winrestview(quickfix_is_open)
--  vim.cmd [[
--  	let quickfix_is_open = winsaveview() "save cursor position
--  	let currentWindow = winnr() "save window cursor is in
--  	copen
--  	execute currentWindow . "wincmd w"
--  	call winrestview(quickfix_is_open)
--  ]]
--end
--
--vim.keymap.set('n', '<leader>h', ':call QuickFixOpen()<CR>', { noremap = true})
vim.keymap.set('n', '<leader>h', ':copen<CR>', { noremap = true })
vim.keymap.set('n', '<leader>j', ':write<CR>:cnext<CR>', { noremap = true })
vim.keymap.set('n', '<leader>k', ':cprevious<CR>', { noremap = true })
vim.keymap.set('n', '<leader>l', ':cclose<CR>', { noremap = true })

-- Since insert mode C-h is backspace, C-l should delete char infront
vim.keymap.set('i', '<C-l>', '<del>', { noremap = true })

-- Surround word with " or < or (
vim.keymap.set('n', '<leader>"', 'viw<esc>a"<esc>hbi"<esc>lel', { noremap = true })
vim.keymap.set('n', '<leader>\'', 'viw<esc>a\'<esc>hbi\'<esc>lel', { noremap = true })
vim.keymap.set('n', '<leader><', 'viw<esc>a><esc>hbi<<esc>lel', { noremap = true })
vim.keymap.set('n', '<leader>(', 'viw<esc>a)<esc>hbi(<esc>lel', { noremap = true })
--Test: flkjal alfkjalf lajslkf

-- copy to end of line, to match behaviour of D and C
vim.keymap.set('n', 'Y', 'y$', { noremap = true })

-- copy and paste to system clipboard
vim.keymap.set('v', '<leader>y', '"+y', { noremap = true })
vim.keymap.set('n', '<leader>p', '"+p', { noremap = true })
vim.keymap.set('n', '<leader>P', '"+P', { noremap = true })

-- Resize split with arrows
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { noremap = true })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { noremap = true })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { noremap = true })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { noremap = true })

-- indent
vim.keymap.set("v", "<", "<gv", { noremap = true })
vim.keymap.set("v", ">", ">gv", { noremap = true })

-- keep clipboard when pasting over visual selection
vim.keymap.set("v", "p", '"_dP', { noremap = true })

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

  if (errorformat ~= nil)
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

vim.keymap.set("n", "<F5>", ":EyestrBuild<CR>", { noremap = true })
vim.keymap.set("n", "<F12>", ":EyestrRun<CR>", { noremap = true })

vim.api.nvim_create_user_command('EESBuild', function()
  local buildCmd =
  "dotnet build /nologo /v:q /property:GenerateFullPaths=true src/GovUk.Education.ExploreEducationStatistics.sln"
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

-- plugins
-- 'easymotion/vim-easymotion',
