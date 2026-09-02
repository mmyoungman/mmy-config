-- Both are external binaries the fuzzy finder shells out to; the Ansible roles
-- install them.
if vim.fn.executable('rg') == 0 then
  print("Ripgrep not installed! fzf-lua live_grep won't work!")
end
if vim.fn.executable('fzf') == 0 then
  print("fzf not installed! fzf-lua won't work!")
end

-- Plugins are managed by `vim.pack` (see the Plugins section below), which
-- landed in 0.12. There is no useful degraded mode without them, so bail here
-- rather than part-loading a config whose `require()` calls would then error.
if vim.fn.has('nvim-0.12') == 0 then
  vim.notify(
    'Neovim 0.12+ required for vim.pack; config not loaded (running ' .. tostring(vim.version()) .. ')',
    vim.log.levels.WARN
  )
  return
end

vim.g.mapleader = '\\'
vim.g.maplocalleader = '\\'

-- The autosave below writes *every* modified buffer, so a blanket strip would
-- silently reformat files opened only to read them. Track which buffers we
-- actually typed in and limit the strip to those. `keeppatterns` stops the
-- substitution clobbering the last search pattern (and lighting up hlsearch).
vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
  desc = 'Remember buffers edited in this session',
  pattern = '*',
  callback = function(event)
    vim.b[event.buf].mmy_edited = true
  end
})

vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Clear whitespace before save, in buffers we edited',
  pattern = '*',
  callback = function(event)
    if not vim.b[event.buf].mmy_edited then return end
    local view = vim.fn.winsaveview()
    vim.api.nvim_buf_call(event.buf, function()
      vim.cmd([[silent! keeppatterns %s/\s\+$//e]])
    end)
    vim.fn.winrestview(view)
  end
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

-- Step through the quickfix list. Two things this has to work around:
--
-- `:cnext` and `:cprevious` move *off* the current entry and stop dead at the
-- ends of the list. A fresh list is already sitting on entry 1, so with a
-- single error `:cnext` has no entry 2 to reach and `:cprevious` has no entry
-- 0 -- both fail and you can never jump to the only error you have. Falling
-- back to the far end wraps the list and fixes that case as a side effect.
--
-- `:update` rather than `:write`, because `:write` rewrites a file even when
-- the buffer is unmodified -- touching the mtime of everything you merely step
-- through, which can retrigger a build watching those files. It also errors in
-- the quickfix window itself (no file name), and an error inside a mapping
-- aborts the rest of it, so `:write` silently ate the jump there.
local function qf_step(step, wrap)
  vim.cmd('silent! update')
  if not pcall(vim.cmd, step) then
    if not pcall(vim.cmd, wrap) then
      vim.notify('Quickfix list is empty', vim.log.levels.WARN)
    end
  end
end

vim.keymap.set('n', '<leader>h', ':copen<CR>', { noremap = true })
vim.keymap.set('n', '<leader>j', function() qf_step('cnext', 'cfirst') end,
  { desc = 'Next quickfix entry' })
vim.keymap.set('n', '<leader>k', function() qf_step('cprevious', 'clast') end,
  { desc = 'Previous quickfix entry' })
vim.keymap.set('n', '<leader>l', ':cclose<CR>', { noremap = true })

-- Since insert mode C-h is backspace, C-l should delete char infront
vim.keymap.set('i', '<C-l>', '<del>', { noremap = true })

-- Surround word with " or < or (
vim.keymap.set('n', '<leader>"', 'viw<esc>a"<esc>hbi"<esc>lel', { noremap = true })
vim.keymap.set('n', '<leader>\'', 'viw<esc>a\'<esc>hbi\'<esc>lel', { noremap = true })
vim.keymap.set('n', '<leader><', 'viw<esc>a><esc>hbi<<esc>lel', { noremap = true })
vim.keymap.set('n', '<leader>(', 'viw<esc>a)<esc>hbi(<esc>lel', { noremap = true })

-- Resize split with arrows
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { noremap = true })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { noremap = true })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { noremap = true })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { noremap = true })

-- keep clipboard when pasting over visual selection
vim.keymap.set("v", "p", '"_dP', { noremap = true })

-- [[ Project tasks ]]
-- Per-project build/run/test commands declared in a `.nvim.lua` at the project
-- root. Enough code to be worth its own file: see lua/project.lua, which
-- documents the declaration format at the top of its second half.
require('project')

-- [[ Plugins ]]
local gh = function(repo) return 'https://github.com/' .. repo end

vim.pack.add({
  gh('tpope/vim-sleuth'),

  gh('easymotion/vim-easymotion'),

  -- LSP
  gh('neovim/nvim-lspconfig'),
  gh('mason-org/mason.nvim'),
  gh('mason-org/mason-lspconfig.nvim'),
  gh('folke/lazydev.nvim'),

  gh('folke/which-key.nvim'),

  gh('lewis6991/gitsigns.nvim'),

  gh('navarasu/onedark.nvim'),

  gh('nvim-lualine/lualine.nvim'),

  gh('ibhagwan/fzf-lua'),
}, { confirm = false })

-- Deleting a line above is not enough: vim.pack leaves the directory on disk,
-- and the next start "repairs" it back into the lockfile. Anything not in the
-- add() above is non-active, so pruning those makes the list here the single
-- source of truth for both.
local stale = vim.iter(vim.pack.get())
  :filter(function(p) return not p.active end)
  :map(function(p) return p.spec.name end)
  :totable()
if #stale > 0 then vim.pack.del(stale) end

-- [[ Plugin setup ]]
require('lazydev').setup({})

require('which-key').setup({})

require('gitsigns').setup({
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

-- Whether any LSP server is still working, for the statusline. Every server
-- reports what it is doing over $/progress -- Roslyn loading a solution, clangd
-- parsing a translation unit -- and this tracks only whether something is
-- outstanding, not what. What you do about it is the same either way: wait.
--
-- vim.lsp.status() is the obvious thing to call here and is what this used to
-- be, but it *drains* the progress ring: each call returns only the messages
-- that arrived since the last one, and nothing between two of them. Sampled
-- once a second by lualine, it mostly caught nothing. The LspProgress event
-- loses nothing.
local lsp_jobs = {}                   -- operations not yet finished
local lsp_busy = ''

vim.api.nvim_create_autocmd('LspProgress', {
  desc = 'Show on the statusline that an LSP server is still working',
  callback = function(ev)
    local key = ('%d/%s'):format(ev.data.client_id, tostring(ev.data.params.token))
    -- `or nil` deletes the entry: a table with a false in it is not empty.
    lsp_jobs[key] = (ev.data.params.value.kind ~= 'end') or nil
    lsp_busy = next(lsp_jobs) and 'LSP indexing' or ''

    -- Both of these, in this order, or nothing appears. lualine hands out a
    -- string it built earlier and only rebuilds on its own timer, so
    -- redrawstatus by itself repaints the stale one; and lualine sets
    -- 'statusline' to a fixed expression rather than to the text, so a rebuild
    -- changes no option and nothing marks the screen dirty. Waiting on a server
    -- is precisely when nothing else is redrawing either -- which is why this
    -- looked like it worked until a load was watched on a real screen rather
    -- than read back out of lualine's cache.
    pcall(function()
      require('lualine').refresh({ place = { 'statusline' }, force = true })
      vim.cmd('redrawstatus')
    end)
  end,
})

require('lualine').setup({
  options = {
    icons_enabled = false,
    theme = 'onedark',
    component_separators = '|',
    section_separators = '',
  },
  sections = {
    lualine_c = {{'filename',path=2}},
    -- "LSP indexing" while any server is still working, tracked just above.
    -- This stands in for fidget.nvim, which showed the same thing as an animated
    -- toast in the corner. If plain text tucked into the statusline turns out to
    -- be too easy to miss, put `gh('j-hui/fidget.nvim')` back in vim.pack.add
    -- above with `require('fidget').setup({})` and drop this component.
    -- lualine_x has to be spelled out in full because naming it replaces the
    -- default components rather than adding to them.
    lualine_x = {
      function() return lsp_busy end,
      'encoding', 'fileformat', 'filetype',
    },
  },
})

vim.o.splitbelow = true
vim.o.splitright = true

-- 'undodir' is deliberately left at its default, ~/.local/state/nvim/undo.
-- This config is symlinked to ~/.config/nvim, so pointing undo there wrote
-- editor state back into the repo working tree, where a `git clean -xdf` would
-- take your undo history with it.
vim.o.undolevels = 1000
vim.o.undoreload = 10000

vim.o.showbreak = '…'

vim.o.writebackup = false
--
vim.o.scrolloff = 5

vim.o.showmatch = true
vim.o.matchpairs = "(:),{:},[:],<:>"

-- Clear search highlighting with <Esc> ('hlsearch' is on by default).
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.wo.number = true

vim.o.mouse = 'a'

vim.o.clipboard = 'unnamedplus'

vim.o.breakindent = true

vim.o.undofile = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.wo.signcolumn = 'yes'

vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience.
--  menuone  show the menu even for a single match
--  noselect never preselect; nothing is inserted until you pick it
--  popup    show the item's documentation in a floating window
--  fuzzy    fuzzy-match against what you have typed so far
vim.o.completeopt = 'menuone,noselect,popup,fuzzy'

vim.o.termguicolors = true

-- [[ Basic Keymaps ]]
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
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Treesitter highlighting for parsers bundled with Neovim',
  pattern = { 'bash', 'sh', 'c', 'python', 'vim' },
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

-- [[ Configure fzf-lua ]]
local fzf = require('fzf-lua')
fzf.setup({ 'telescope' })

vim.keymap.set('n', '<leader>?', fzf.oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', fzf.buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
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

    -- K mapping is redundant, but kept deliberately as reminder it exists
    nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

    nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')

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

-- Roslyn does not scan for projects: it opens whatever solution it is told to,
-- once, and every C# file outside that solution then falls back to single-file
-- semantics -- syntax highlighting, but `gd` on a class in the same namespace
-- silently does nothing. lspconfig picks "the first solution we find" by
-- iterating vim.fs.dir(), which yields entries in *filesystem* order, so a repo
-- holding two .sln files gets a coin toss.
--
-- A project names the one it means by setting `vim.g.roslyn_solution` in its
-- `.nvim.lua` (relative to the root, or absolute); 'exrc' loads that during
-- startup, before the LSP client initialises. Note this misses the VimEnter
-- fallback in project.lua -- opening a file by absolute path from outside the
-- project sets the global too late -- so it wants nvim started from the tree.
-- A repo declaring it in this config instead, as `projects/<name>.lua`, has no
-- such constraint: load_stored() runs at require time either way.
--
-- Without a declaration, sort before taking the first, so an undeclared repo at
-- least fails the same way every time rather than differing between starts.
--
-- This replaces lspconfig's on_init rather than adding to it: vim.lsp.config
-- merges with tbl_deep_extend('force'), and their on_init is a one-element
-- list, so ours takes index 1 and theirs never runs.
vim.lsp.config('roslyn_ls', {
  on_init = {
    function(client)
      local root = client.config.root_dir

      local declared = vim.g.roslyn_solution
      if declared then
        -- The declaration lives in a `.nvim.lua` at the *repo* root, while
        -- root_dir is wherever the solution sits -- often `src/`. So a
        -- repo-relative path does not resolve against root_dir. Try root_dir
        -- and then each parent, which reads correctly written either way.
        local path = vim.startswith(declared, '/') and declared or nil
        local dir = root
        while not path and dir do
          local candidate = vim.fs.joinpath(dir, declared)
          if vim.uv.fs_stat(candidate) then path = candidate end
          local parent = vim.fs.dirname(dir)
          dir = parent ~= dir and parent or nil
        end
        if path and vim.uv.fs_stat(path) then
          return client:notify('solution/open', { solution = vim.uri_from_fname(path) })
        end
        vim.notify(('roslyn_ls: g:roslyn_solution %q not found from %s, falling back')
          :format(declared, root), vim.log.levels.WARN)
      end

      local solutions, projects = {}, {}
      for entry, type in vim.fs.dir(root) do
        if type == 'file' then
          if entry:match('%.slnx?$') then
            solutions[#solutions + 1] = entry
          elseif entry:match('%.csproj$') then
            projects[#projects + 1] = entry
          end
        end
      end
      table.sort(solutions)

      if solutions[1] then
        -- Worth saying out loud: the symptom of guessing wrong is not an error,
        -- it is navigation quietly doing nothing in half the repo.
        if #solutions > 1 then
          vim.notify(('roslyn_ls: %d solutions in %s, opening %s. Set '
            .. 'vim.g.roslyn_solution in .nvim.lua to pick another.')
            :format(#solutions, root, solutions[1]), vim.log.levels.WARN)
        end
        client:notify('solution/open', {
          solution = vim.uri_from_fname(vim.fs.joinpath(root, solutions[1])),
        })
      elseif projects[1] then
        client:notify('project/open', {
          projects = vim.tbl_map(function(p)
            return vim.uri_from_fname(vim.fs.joinpath(root, p))
          end, projects),
        })
      end
    end,
  },
})

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {
    'clangd', 'gopls', 'templ', 'pyright', 'lua_ls',
    'bashls', 'robotframework_ls', 'roslyn_ls',
  },
})
