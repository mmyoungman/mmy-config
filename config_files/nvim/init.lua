-- Both are external binaries the fuzzy finder shells out to; the Ansible roles
-- install them.
if vim.fn.executable('rg') == 0 then
  print("Ripgrep not installed! fzf-lua live_grep won't work!")
end
if vim.fn.executable('fzf') == 0 then
  print("fzf not installed! fzf-lua won't work!")
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

-- keep clipboard when pasting over visual selection
vim.keymap.set("v", "p", '"_dP', { noremap = true })

function Build(buildCmd, errorformat)
  local separateOutputCmd = string.format("%s 2> stderr.log", buildCmd)
  local stdout = vim.fn.system(separateOutputCmd)

  if #stdout > 0 then
    vim.notify(stdout)
  end

  -- for debugging
  --print(separateOutputCmd)
  --vim.fn.system("cat stderr.log")

  vim.opt.errorformat = errorformat
  vim.cmd("silent cfile stderr.log")

  if vim.tbl_isempty(vim.fn.getqflist()) then
    vim.cmd("cclose")
    -- if errors in stderroutput not caught by quickfix, notify user
    if vim.fn.getfsize("stderr.log") ~= 0 then
      vim.notify("Build failed:")
      vim.notify(vim.fn.system("cat stderr.log"))
    end
  else
    vim.cmd("copen")
  end

  vim.cmd("silent !rm stderr.log")
end

function Run(runCmd, errorformat)
  local runOutputFileCmd = string.format("silent !%s 2> stderr.log", runCmd)

  -- for debugging
  --print(runOutputFileCmd)
  --vim.cmd("!cat runOutputFile")

  vim.cmd(runOutputFileCmd)

  if (errorformat ~= nil)
  then
    vim.opt.errorformat = errorformat
    vim.cmd("silent cfile stderr.log")

    if vim.tbl_isempty(vim.fn.getqflist()) then
      vim.cmd("cclose")
      -- if errors in stderroutput not caught by quickfix, notify user
      if vim.fn.getfsize("stderr.log") ~= 0 then
        vim.notify("Run failed:")
        vim.notify(vim.fn.system("cat stderr.log"))
      end
    else
      vim.cmd("copen")
    end
  end

  vim.cmd("silent !rm stderr.log")
end

vim.api.nvim_create_user_command('EyestrBuild', function()
  local buildCmd = "./scripts/build.sh"
  local errorformat = "%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m,%-G%.%#"
  Build(buildCmd, errorformat)
end, {})

vim.api.nvim_create_user_command('EyestrRun', function()
  Run("./scripts/run.sh", "[%tRROR] (%f:%l) %m,[D%tBUG] (%f:%l) %m,%-G%.%#")
end, {})

--vim.keymap.set("n", "<F5>", ":EyestrBuild<CR>", { noremap = true })
--vim.keymap.set("n", "<F12>", ":EyestrRun<CR>", { noremap = true })

vim.api.nvim_create_user_command('EESBuild', function()
  local buildCmd =
  "dotnet build /nologo /v:q /property:GenerateFullPaths=true src/GovUk.Education.ExploreEducationStatistics.sln"
  local errorformat = "%f(%l\\,%c): %trror %m,%-G%.%#"
  Build(buildCmd, errorformat)
end, {})

vim.api.nvim_create_user_command('WebGameLinuxBuild', function()
  local buildCmd = "./build_linux.sh"
  local errorformat = "%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m,%-G%.%#"
  Build(buildCmd, errorformat)
end, {})

vim.api.nvim_create_user_command('WebGameLinuxRun', function()
  Run("./build/main", "[%tRROR] (%f:%l) %m,[D%tBUG] (%f:%l) %m,%-G%.%#")
end, {})

vim.keymap.set("n", "<F5>", ":WebGameLinuxBuild<CR>", { noremap = true })
vim.keymap.set("n", "<F12>", ":WebGameLinuxRun<CR>", { noremap = true })

-- [[ Plugins ]]
-- Managed by Neovim's built-in plugin manager, `:help vim.pack`.
--  :lua vim.pack.update()                -- update all, review, `:w` to confirm
--  :lua vim.pack.update({ 'fzf-lua' })   -- update just one
--  :lua vim.pack.update(nil, { offline = true })  -- just list what's installed
-- The lockfile lives next to this file as `nvim-pack-lock.json`; commit it.

if vim.fn.has('nvim-0.12') == 0 then
  vim.notify(
    'Neovim 0.12+ required for vim.pack; plugins not loaded (running ' .. tostring(vim.version()) .. ')',
    vim.log.levels.WARN
  )
  return
end

local gh = function(repo) return 'https://github.com/' .. repo end

-- No plugin here needs a compile step, so there is no `PackChanged` build hook.
-- (There used to be one for telescope-fzf-native's C matcher.)

vim.pack.add({
  -- Detect tabstop and shiftwidth automatically
  gh('tpope/vim-sleuth'),

  gh('easymotion/vim-easymotion'),

  -- LSP
  gh('neovim/nvim-lspconfig'),
  gh('mason-org/mason.nvim'),
  gh('mason-org/mason-lspconfig.nvim'),
  -- LSP progress is `vim.lsp.status()` in the lualine config below.
  -- Lua LS config for editing Neovim config itself
  gh('folke/lazydev.nvim'),

  -- Autocompletion is Neovim's built-in `vim.lsp.completion`; see below.

  -- Shows pending keybinds
  gh('folke/which-key.nvim'),

  -- Git signs in the gutter, plus utilities for managing changes
  gh('lewis6991/gitsigns.nvim'),

  -- Theme inspired by Atom
  gh('navarasu/onedark.nvim'),

  gh('nvim-lualine/lualine.nvim'),

  -- Fuzzy finder. Wraps the external `fzf` binary (installed by the Ansible
  -- roles), so unlike telescope it needs no Lua dependencies and no C build.
  gh('ibhagwan/fzf-lua'),
}, { confirm = false })

-- [[ Plugin setup ]]
-- `vim.pack` does not call `setup()` for you the way lazy.nvim's `opts` did,
-- so each plugin is configured explicitly below.

require('lazydev').setup({})

require('which-key').setup({})

require('gitsigns').setup({
  -- See `:help gitsigns.txt`
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
  on_attach = function(bufnr)
    vim.keymap.set('n', '<leader>gp', require('gitsigns').preview_hunk, { buffer = bufnr, desc = 'Preview git hunk' })

    -- don't override the built-in and fugitive keymaps
    local gs = require('gitsigns')
    vim.keymap.set({ 'n', 'v' }, ']c', function()
      if vim.wo.diff then return ']c' end
      vim.schedule(function() gs.nav_hunk('next') end)
      return '<Ignore>'
    end, { expr = true, buffer = bufnr, desc = "Jump to next hunk" })
    vim.keymap.set({ 'n', 'v' }, '[c', function()
      if vim.wo.diff then return '[c' end
      vim.schedule(function() gs.nav_hunk('prev') end)
      return '<Ignore>'
    end, { expr = true, buffer = bufnr, desc = "Jump to previous hunk" })
  end,
})

vim.cmd.colorscheme('onedark')

require('lualine').setup({
  options = {
    icons_enabled = false,
    theme = 'onedark',
    component_separators = '|',
    section_separators = '',
  },
  sections = {
    lualine_c = {{'filename',path=2}},
    -- LSP progress ("clangd: parsing 34/120"), builtin since 0.10. This stands
    -- in for fidget.nvim, which showed the same information as an animated
    -- toast in the corner. If plain text tucked into the statusline turns out
    -- to be too easy to miss, put `gh('j-hui/fidget.nvim')` back in
    -- vim.pack.add above with `require('fidget').setup({})` and drop this line.
    -- lualine_x has to be spelled out in full because naming it replaces the
    -- default components rather than adding to them.
    lualine_x = { vim.lsp.status, 'encoding', 'fileformat', 'filetype' },
  },
})

-- Indentation is left to vim-sleuth, which detects it per project.

vim.o.splitbelow = true
vim.o.splitright = true

-- Must be expanded here: `vim.o.*` assigns the raw string, so '~' and '$HOME'
-- are NOT expanded and nvim creates a literal '~'/'$HOME' directory instead.
-- (Only `:set undodir=...` does that expansion. Nothing to do with the symlink.)
vim.o.undodir = vim.fn.expand('~/.config/nvim/undo')
vim.o.undolevels = 1000
vim.o.undoreload = 10000

vim.o.showbreak = '…'

-- 'backup' is off by default; only 'writebackup' needs changing.
vim.o.writebackup = false
--vim.cmd('!mkdir -p ~/.config/nvim/backup', { silent = true })
--vim.opt.backup = true
--vim.opt.backupdir = '~/.config/nvim/backup/'
--
vim.o.scrolloff = 5

vim.o.showmatch = true
vim.o.matchpairs = "(:),{:},[:],<:>"

-- Clear search highlighting with <Esc> ('hlsearch' is on by default).
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience.
--  menuone  show the menu even for a single match
--  noselect never preselect; nothing is inserted until you pick it
--  popup    show the item's documentation in a floating window
--  fuzzy    fuzzy-match against what you have typed so far
vim.o.completeopt = 'menuone,noselect,popup,fuzzy'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Highlight on yank ]]
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.hl.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- [[ Treesitter ]]
-- nvim-treesitter's `master` branch is archived, so it is no longer installed.
-- Neovim ships parsers for these filetypes; turn highlighting on for the ones
-- it does not already enable itself (it does lua/markdown/help/query).
-- Incremental selection is now built in: see `:help v_an` / `:help v_in`.
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Treesitter highlighting for parsers bundled with Neovim',
  pattern = { 'bash', 'sh', 'c', 'python', 'vim' },
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

-- [[ Configure fzf-lua ]]
-- The 'telescope' profile makes the popup and its in-picker keys behave the way
-- telescope did (<C-x> split, <C-v> vsplit, <C-t> tab), so the muscle memory
-- carries over. `:FzfLua profiles` previews the alternatives.
local fzf = require('fzf-lua')
fzf.setup({ 'telescope' })

-- See `:help fzf-lua` or `:FzfLua` for the full picker list.
vim.keymap.set('n', '<leader>?', fzf.oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', fzf.buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  -- `blines` is the current-buffer fuzzy search; no preview, since the preview
  -- would just be showing the buffer you are already looking at.
  fzf.blines({ winopts = { preview = { hidden = true } } })
end, { desc = '[/] Fuzzily search in current buffer' })

vim.keymap.set('n', '<leader>gf', fzf.git_files, { desc = 'Search [G]it [F]iles' })
vim.keymap.set('n', '<leader>sf', fzf.files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', fzf.helptags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', fzf.grep_cword, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', fzf.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', fzf.diagnostics_document, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', fzf.resume, { desc = '[S]earch [R]esume' })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end,
  { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end,
  { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- [[ Configure LSP ]]
--  These keymaps get set when an LSP connects to a particular buffer.
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP keymaps',
  callback = function(event)
    local bufnr = event.buf
    local nmap = function(keys, func, desc)
      if desc then
        desc = 'LSP: ' .. desc
      end

      vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end

    nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

    nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
    nmap('gr', fzf.lsp_references, '[G]oto [R]eferences')
    nmap('gI', fzf.lsp_implementations, '[G]oto [I]mplementation')
    nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
    nmap('<leader>ds', fzf.lsp_document_symbols, '[D]ocument [S]ymbols')
    nmap('<leader>ws', fzf.lsp_live_workspace_symbols, '[W]orkspace [S]ymbols')

    -- See `:help K` for why this keymap
    nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

    -- Lesser used LSP functionality
    nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')

    -- Create a command `:Format` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
      vim.lsp.buf.format()
    end, { desc = 'Format current buffer with LSP' })

    -- Built-in completion, `:help vim.lsp.completion`. `autotrigger` opens the
    -- menu on the server's own triggerCharacters ('.', ':', '->', ...); for
    -- anything else use <C-Space> below, or <C-x><C-o> ('omnifunc' is set for
    -- us on attach).
    vim.lsp.completion.enable(true, event.data.client_id, bufnr, { autotrigger = true })
  end,
})

-- Completion menu keys. The menu is Vim's own |ins-completion| popup, so
-- <C-n>/<C-p> move and <C-e> aborts; these make <CR>/<Tab> behave as they did
-- under nvim-cmp without shadowing them when no menu is open.
vim.keymap.set('i', '<C-Space>', function() vim.lsp.completion.get() end,
  { desc = 'Trigger LSP completion' })
vim.keymap.set('i', '<CR>', function()
  return vim.fn.pumvisible() == 1 and '<C-y>' or '<CR>'
end, { expr = true })
-- <Tab> keeps the nvim-cmp precedence: menu first, then snippet placeholders,
-- then a literal tab. Neovim installs its own <Tab> mapping for snippet jumps
-- (`:help vim.snippet.jump`); this replaces it, so it has to handle that case.
vim.keymap.set({ 'i', 's' }, '<Tab>', function()
  if vim.fn.pumvisible() == 1 then return '<C-n>' end
  if vim.snippet.active({ direction = 1 }) then return '<Cmd>lua vim.snippet.jump(1)<CR>' end
  return '<Tab>'
end, { expr = true, silent = true })
vim.keymap.set({ 'i', 's' }, '<S-Tab>', function()
  if vim.fn.pumvisible() == 1 then return '<C-p>' end
  if vim.snippet.active({ direction = -1 }) then return '<Cmd>lua vim.snippet.jump(-1)<CR>' end
  return '<S-Tab>'
end, { expr = true, silent = true })

-- Per-server overrides. The base config for each of these comes from
-- nvim-lspconfig's `lsp/<name>.lua`; see `:help vim.lsp.config()`.
vim.lsp.config('pyright', {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = 'off',
      },
    },
  },
})

vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
})

-- Install the servers above, then enable them. mason-lspconfig calls
-- `vim.lsp.enable()` for every installed server automatically.
require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = { 'clangd', 'gopls', 'templ', 'pyright', 'lua_ls' },
})

-- Snippets from LSP completion items expand via the built-in `vim.snippet`;
-- placeholder navigation is on <Tab>/<S-Tab> alongside the completion menu.
