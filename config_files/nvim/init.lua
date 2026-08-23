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

-- [[ Build & run ]]
-- A project declares how it builds in a `.nvim.lua` at its root -- see
-- Project() at the end of this section; everything generic lives here so that
-- file stays a plain declaration. 'exrc' is what loads it: it searches the cwd
-- and every parent directory, and `:trust` gates it so a repo you have just
-- cloned cannot run code at you. See `:help 'exrc'`.
vim.o.exrc = true

-- 'makeprg' and 'errorformat' are |global-local|: a buffer-local value (which
-- is what `:compiler` and the ftplugins set) wins over the global one.
local function buf_or_global(name)
  local buf_value = vim.bo[name]
  return buf_value ~= '' and buf_value or vim.o[name]
end

-- `:make` does all of this already, but synchronously -- it freezes the UI
-- until the compiler exits. vim.system() runs the build in the background;
-- 'errorformat' still does the parsing, via setqflist()'s `efm`.
local build_running = false
local build_handle = nil             -- the vim.system object of the running build
local build_cancel_requested = false

-- The quickfix list is only a *view* of a build: 'errorformat' drops every
-- line it does not recognise, so a bash error, a missing tool, or any compiler
-- we have no format for would vanish from it. Keep the raw output of the last
-- build so :BuildLog can always show exactly what happened.
local last_build = {}

-- Builds are async, so C-c in the UI cannot reach them: this is the
-- interrupt. The build runs detached -- a process-group leader -- so the
-- negative-pid signal reaches the whole group: a script that spawned children
-- of its own cannot outlive the stop by holding the output pipe open.
vim.api.nvim_create_user_command('BuildStop', function()
  if not build_running or not build_handle then
    return vim.notify('No build is running', vim.log.levels.WARN)
  end
  build_cancel_requested = true
  pcall(vim.uv.kill, -build_handle.pid, 'sigterm')
  build_handle:kill('sigterm')
end, { desc = 'Kill the running :Build' })

vim.api.nvim_create_user_command('Build', function(opts)
  if build_running then
    return vim.notify('Build already running', vim.log.levels.WARN)
  end
  vim.cmd('silent! wall')

  -- 'makeprg' may hold pipes, quotes and `%`, so hand it to the shell rather
  -- than splitting it into argv here; expandcmd() does the `%`/`#` expansion
  -- that :make would have done.
  local prg = buf_or_global('makeprg')
  local cmd = vim.fn.expandcmd(opts.args ~= '' and (prg .. ' ' .. opts.args) or prg)
  local efm = buf_or_global('errorformat')

  build_running = true
  build_cancel_requested = false
  vim.notify(cmd)
  -- Merge stderr into stdout in the shell, rather than concatenating the two
  -- captured strings afterwards: concatenating puts every stderr line after
  -- every stdout line, and 'errorformat' is order-sensitive -- its %D/%X
  -- "Entering/Leaving directory" directives can only track the compiler's cwd
  -- against genuinely interleaved output. `:make` merges for the same reason,
  -- via 'shellpipe' (`2>&1| tee`). The subshell keeps the redirect applied to
  -- the whole command, not just the last stage of a `&&` chain.
  local shell_cmd = ('(%s) 2>&1'):format(cmd)
  -- pcall: if the spawn itself fails, undo the running flag rather than
  -- wedging :Build until restart. `detach` makes the shell a process-group
  -- leader, which is what lets :BuildStop signal the whole group.
  local ok, handle_or_err = pcall(vim.system,
    { vim.o.shell, vim.o.shellcmdflag, shell_cmd },
    { text = true, detach = true }, function(res)
    vim.schedule(function()
      build_running = false
      build_handle = nil
      local output = res.stdout or ''
      -- A killed process reports a signal rather than a meaningful exit code.
      -- res.signal is a number: 0 on a normal exit, the signum otherwise;
      -- report our own stop request (or an external SIGTERM) as a
      -- cancellation, not a failure.
      local cancelled = build_cancel_requested or (res.signal or 0) ~= 0
      last_build = { cmd = cmd, code = res.code, output = output }

      -- setqflist() resolves relative filenames against the cwd at the moment
      -- the list is built, and the command ran from the project root (Project()
      -- prefixes a `cd`). A compiler given `src/foo.c`, or a test printing
      -- `tests/bar.c:41`, therefore reports paths relative to the root, not to
      -- wherever nvim happened to be started -- so parse from there. While
      -- still sitting in the root, rewrite every parsed filename to an
      -- absolute path: relative ones would otherwise resolve against the cwd
      -- of whichever window you jump (<leader>j/k) *from*, which is often not
      -- the root. pcall guards the whole dance -- a bad merged 'errorformat'
      -- must not leave your window silently cd'd into the project.
      local previous = vim.g.project_root and vim.fn.chdir(vim.g.project_root) or nil
      local set_ok, set_err = pcall(vim.fn.setqflist, {}, ' ', {
        title = cmd,
        lines = vim.split(output, '\n', { trimempty = true }),
        efm = efm,
      })
      if set_ok then
        local items = vim.fn.getqflist({ items = 0 }).items
        for _, item in ipairs(items) do
          if item.filename and item.filename ~= '' then
            item.filename = vim.fn.fnamemodify(item.filename, ':p')
          end
        end
        vim.fn.setqflist({}, 'r', { title = cmd, items = items })
      end
      if previous and previous ~= '' then vim.fn.chdir(previous) end
      if not set_ok then return vim.notify(set_err, vim.log.levels.ERROR) end
      -- Opens the quickfix window only if 'errorformat' matched something and
      -- closes it if not, so a clean build just quietly succeeds.
      vim.cmd('cwindow')

      -- Lines 'errorformat' did *not* match are still added to the list, as
      -- entries with valid=0, so a non-empty list does not mean the build
      -- produced anything jumpable -- count the valid ones. A non-zero exit is
      -- always reported, even when there are errors in quickfix, because the
      -- interesting failure is often the one that did not parse: `bear: command
      -- not found` next to three real compile errors. When nothing parsed at
      -- all, the raw output goes straight into the message.
      local qf = vim.fn.getqflist()
      local matched = #vim.tbl_filter(function(e) return e.valid == 1 end, qf)
      if cancelled then
        return vim.notify(
          ('Build cancelled: %d entries kept. :BuildLog for raw output'):format(matched),
          vim.log.levels.WARN
        )
      end
      if res.code ~= 0 then
        local msg = ('Build failed (exit %d): %d in quickfix, %d unparsed. :BuildLog for raw output')
          :format(res.code, matched, #qf - matched)
        vim.notify(
          matched == 0 and (msg .. '\n' .. vim.trim(output)) or msg,
          vim.log.levels.ERROR
        )
      else
        -- An exit code is only as honest as the build script that returns it.
        -- A shell script whose last statement is an untaken `if` exits 0 no
        -- matter how the compiler fared, so a clean exit sitting next to
        -- parsed errors means the failure got swallowed on the way out. Trust
        -- 'errorformat' over the exit code here and say so, rather than
        -- letting a broken build pass for a quiet success. A build that only
        -- warns, though, did genuinely succeed, so grade the entries first.
        --
        -- %t stores the compiler's severity character verbatim, in whatever
        -- case it printed it ('e' from "error:", 'w' from "warning:"), and is
        -- empty for a format carrying no severity at all. So count the
        -- explicit errors -- but if nothing in the list was graded, as with a
        -- custom efm like `FAIL %f:%l %m` where every match is a failure by
        -- construction, fall back to the whole list rather than going quiet
        -- on a format we cannot read severities from.
        local function count(predicate)
          return #vim.tbl_filter(function(e) return e.valid == 1 and predicate(e) end, qf)
        end
        local errors = count(function(e) return e.type:lower() == 'e' end)
        local graded = count(function(e) return e.type ~= '' end) > 0
        local suspect = errors > 0 and errors or (graded and 0 or matched)
        if suspect > 0 then
          vim.notify(
            ('Build exited 0 but %d error(s) parsed -- exit code likely swallowed by the build script')
              :format(suspect),
            vim.log.levels.WARN
          )
        end
      end
      -- Unlike sync :make there is no automatic jump: this fires while you
      -- may be typing. A project that wants :make's behavior adds
      -- `vim.g.build_jump_first = true` to its .nvim.lua.
      if matched > 0 and vim.g.build_jump_first then vim.cmd('cc 1') end
    end)
  end)
  if not ok then
    build_running = false
    return vim.notify(('Build failed to start: %s'):format(handle_or_err), vim.log.levels.ERROR)
  end
  build_handle = handle_or_err
end, { nargs = '*', desc = 'Build asynchronously into the quickfix list' })

-- The unfiltered truth about the last build, for when quickfix looks wrong or
-- suspiciously empty. `gF` jumps to any file:line in here too, and `:cbuffer`
-- re-parses the whole thing into quickfix.
vim.api.nvim_create_user_command('BuildLog', function()
  if not last_build.cmd then
    return vim.notify('No build has run yet', vim.log.levels.WARN)
  end
  vim.cmd('botright new')
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile = 'nofile', 'wipe', false
  -- Same treatment as :Run's terminal: paths in the log are relative to the
  -- project root, so give this window that cwd for gF and :cbuffer.
  if vim.g.project_root then
    vim.cmd('lcd ' .. vim.fn.fnameescape(vim.g.project_root))
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(
    ('$ %s\n[exit %d]\n\n%s'):format(last_build.cmd, last_build.code, last_build.output),
    '\n'))
  vim.bo[buf].modified = false
end, { desc = 'Raw output of the last :Build' })

-- Running is not the same problem as building: you usually want to watch the
-- program and type at it, not scrape its stderr. So :Run gets a terminal
-- split. To chase a `file.c:42:` in its log, `gF` on the reference jumps
-- straight there; <leader>cq instead pushes the whole log through
-- 'errorformat' into quickfix, so <leader>j / <leader>k walk the references.
-- Buffer of the current run terminal; :Run keeps exactly one alive.
local run_buf

vim.api.nvim_create_user_command('Run', function(opts)
  local cmd = opts.args ~= '' and opts.args or vim.g.runprg
  if not cmd or cmd == '' then
    return vim.notify(
      'Nothing to run: pass a command, or set vim.g.runprg in the project .nvim.lua',
      vim.log.levels.WARN
    )
  end
  vim.cmd('silent! wall')
  -- One run slot: kill the previous program and clear it out, so <leader>xr is
  -- a predictable restart instead of stacking splits full of old servers.
  if run_buf and vim.api.nvim_buf_is_valid(run_buf) then
    local job = vim.b[run_buf].terminal_job_id
    if job then pcall(vim.fn.jobstop, job) end
    for _ = 1, 10 do
      local win = vim.fn.bufwinid(run_buf)
      if win == -1 then break end
      pcall(vim.api.nvim_win_close, win, true)
    end
    pcall(vim.api.nvim_buf_delete, run_buf, { force = true })
  end
  vim.cmd('botright split | terminal ' .. vim.fn.expandcmd(cmd))
  run_buf = vim.api.nvim_get_current_buf()
  -- The run's own 'errorformat' rides on the terminal buffer, so <leader>cq
  -- parses the program's log format rather than the compiler's -- a line like
  -- "[ERROR] (src/game.c:12) oops" matches no compiler format at all.
  if vim.g.runefm then vim.bo.errorformat = vim.g.runefm end
  -- The program runs from the project root, so paths it logs are relative to
  -- that, not to wherever nvim was started. Give the terminal window the same
  -- cwd, so gF and <leader>cq resolve them.
  if vim.g.project_root then
    vim.cmd('lcd ' .. vim.fn.fnameescape(vim.g.project_root))
  end
  -- Output is only "tailed" while the cursor is on the last line (`:help
  -- terminal`). A terminal opens in Normal mode with the cursor at the top,
  -- where it stays, so the view falls behind as soon as the program prints
  -- more than a screenful. Parking the cursor on the last line makes it
  -- follow. Note this stays in Normal mode on purpose -- `startinsert` would
  -- tail too, but then keystrokes go to the program and gF / <leader>cq stop
  -- working without first escaping terminal-mode.
  vim.cmd('normal! G')
end, { nargs = '*', desc = 'Run the program in a terminal split' })

vim.api.nvim_create_autocmd('TermOpen', {
  desc = 'Let a terminal log be sent to the quickfix list',
  callback = function(event)
    vim.keymap.set('n', '<leader>cq', '<Cmd>cbuffer<CR><Cmd>cwindow<CR>',
      { buffer = event.buf, desc = 'Terminal output -> [q]uickfix' })
  end,
})

vim.keymap.set('n', '<leader>xb', '<Cmd>Build<CR>', { desc = '[B]uild' })
vim.keymap.set('n', '<leader>xr', '<Cmd>Run<CR>', { desc = '[R]un' })

-- [[ Project declarations ]]
-- A project's `.nvim.lua` should be a declaration and nothing more:
--
--     Project({
--       lang  = 'c',                       -- default format; { 'c', 'go' } if mixed
--       build = './build_linux.sh',        -- :Build  <leader>xb
--       test  = './build_tests.sh',        -- :Test   <leader>xt
--       wasm  = './build_wasm.sh',         -- any other key becomes :Wasm
--       -- a command that prints in its own format overrides it:
--       run   = { './build_linux.sh --run', efm = '[%t%*[A-Z]] (%f:%l) %m' },
--     })
--     -- optional extras:
--     vim.g.build_jump_first = true        -- jump to the first error on a
--                                          -- failed build (off by default:
--                                          -- the notification lands while
--                                          -- you may be typing)
--
-- Each entry is a command string, or a table `{ '<command>', lang = ... }` or
-- `{ '<command>', efm = ... }` when that command's output does not look like
-- the project default. This matters more than it sounds: a compiler, a test
-- runner and the program's own log are three different formats, and a build's
-- 'errorformat' will not match a line like "[ERROR] (src/game.c:12) oops".
-- `run`'s format rides on the terminal buffer, so <leader>cq parses the
-- program's log rather than the compiler's.
--
-- Everything runs from the project root -- the directory holding the
-- `.nvim.lua` -- because build scripts routinely refuse to run anywhere else,
-- and 'exrc' searching upwards means nvim is often started in a subdirectory.

-- Language name -> the compiler plugin that knows its 'errorformat', from
-- $VIMRUNTIME/compiler. Names not listed here are used as-is, so `lang = 'go'`,
-- `lang = 'cargo'` or `lang = 'pytest'` all work without an entry.
local compiler_alias = {
  c = 'gcc', cpp = 'gcc', objc = 'gcc',
  rust = 'cargo', zig = 'zig_build', python = 'pyright',
  typescript = 'tsc', javascript = 'eslint',
}

-- 'exrc' does not stop at the first `.nvim.lua` it finds: it loads the nearest
-- one and then keeps walking up, so in a monorepo the repo-root file runs
-- *last* and would clobber the sub-project's. Nearest-wins instead -- the
-- first declaration sticks and later (outer) ones are ignored, so
-- `frontend/.nvim.lua` beats the root when you are working in frontend/.
local project_declared = false

function Project(spec)
  if project_declared then return end
  project_declared = true

  -- The root is the directory of whatever called us, i.e. the `.nvim.lua`
  -- itself: stack level 2, with `@` marking a real filename.
  local source = debug.getinfo(2, 'S').source
  local root = source:sub(1, 1) == '@' and vim.fs.dirname(source:sub(2)) or assert(vim.uv.cwd())

  local function at_root(cmd)
    return ('cd %s && %s'):format(vim.fn.shellescape(root), cmd)
  end

  -- Turn one entry into { cmd, efm }. An explicit `efm` wins; otherwise `lang`
  -- -- the entry's own, falling back to the project default -- names compiler
  -- plugins whose formats get concatenated. 'errorformat' is a comma-separated
  -- list of alternatives Vim tries in turn, so a mixed-language build merges
  -- them rather than having to pick one.
  local function resolve(entry)
    local cmd = type(entry) == 'string' and entry or entry[1]
    local opts = type(entry) == 'table' and entry or {}

    -- `efm` and `lang` combine rather than compete: a test runner prints its
    -- own failures *and* the compile errors from building the tests, so :Test
    -- wants both formats. The project-wide `lang` is only inherited by an entry
    -- that asks for no format of its own -- otherwise `run`, whose log looks
    -- nothing like a compiler, would pick up a format that can only mismatch.
    local lang = opts.lang or (opts.efm == nil and spec.lang or nil)
    local langs = lang == nil and {} or (type(lang) == 'table' and lang or { lang })
    local formats = {}
    for _, name in ipairs(langs) do
      name = compiler_alias[name] or name
      -- The `!` sets the *global* option, which is what we read back here.
      if pcall(vim.cmd, 'compiler! ' .. name) then
        -- Several compiler plugins (tsc among them) end their format with
        -- `%-G%.%#`, a catch-all that discards every line they do not
        -- recognise -- exactly the line you need when a build script dies on
        -- `bear: command not found`. It also swallows any format merged after
        -- it. Drop it, so unrecognised lines stay in the quickfix list as
        -- unjumpable entries instead of disappearing.
        formats[#formats + 1] = (vim.o.errorformat:gsub(',%%%-G%%%.%%%#$', ''))
      else
        vim.notify(('Project: no compiler plugin %q, see $VIMRUNTIME/compiler'):format(name),
          vim.log.levels.WARN)
      end
    end
    -- The entry's own format goes first, so it wins on a line both could match.
    if opts.efm then table.insert(formats, 1, opts.efm) end
    return {
      cmd = at_root(cmd),
      efm = #formats > 0 and table.concat(formats, ',') or nil,
    }
  end

  -- resolve() runs `:compiler!`, which clobbers the global 'makeprg' AND
  -- 'errorformat' as a side effect, so resolve everything first and only then
  -- decide what the global values should be.
  local original_efm, original_makeprg = vim.o.errorformat, vim.o.makeprg
  local resolved = {}
  for key, entry in pairs(spec) do
    if key ~= 'lang' then resolved[key] = resolve(entry) end
  end

  -- The build's format becomes the global one, <leader>xb being the common
  -- case. With no `build` key the originals go back -- pairs() order is
  -- random, so without this, whichever compiler plugin resolved last would
  -- quietly donate its 'makeprg' (pyright's, cargo's...) to :Build.
  vim.o.errorformat = (resolved.build and resolved.build.efm) or original_efm
  vim.o.makeprg = resolved.build and resolved.build.cmd or original_makeprg
  if resolved.run then
    vim.g.runprg, vim.g.runefm = resolved.run.cmd, resolved.run.efm
  end
  -- :Run needs this to resolve the relative paths a program logs. A C program's
  -- __FILE__ is the path the compiler was given ("src/rules.c"), which is
  -- relative to the root the build ran from, not to wherever nvim was started.
  vim.g.project_root = root

  -- Every other key becomes a :Capitalised command reusing :Build's async
  -- quickfix. :Build reads 'makeprg' and 'errorformat' synchronously before it
  -- forks, so putting the old values back on the next line is safe, and
  -- <leader>xb goes on meaning the normal build.
  for key, r in pairs(resolved) do
    if key ~= 'build' and key ~= 'run' then
      local name = key:sub(1, 1):upper() .. key:sub(2)
      vim.api.nvim_create_user_command(name, function(opts)
        local makeprg, efm = vim.o.makeprg, vim.o.errorformat
        vim.o.makeprg = r.cmd
        if r.efm then vim.o.errorformat = r.efm end
        vim.cmd('Build ' .. opts.args)
        vim.o.makeprg, vim.o.errorformat = makeprg, efm
      end, { nargs = '*', desc = r.cmd })
      -- <leader>xt completes the x{b,r,t} trio when a project declares tests;
      -- other generated commands stay :Command-only.
      if key == 'test' then
        vim.keymap.set('n', '<leader>xt', '<Cmd>' .. name .. '<CR>', { desc = '[T]est' })
      end
    end
  end
end

-- 'exrc' searches the *cwd* and its parents, not the file you opened, so
-- `nvim ~/projects/foo/src/x.c` from somewhere else gets no project at all:
-- :Build falls back to plain `make` and dies on a repo with no makefile, and
-- :Test does not exist. Search upward from the first file as well.
-- vim.secure.read() applies the same `:trust` gate 'exrc' does, and naming the
-- chunk `@<path>` keeps debug.getinfo() in Project() pointing at the real file.
vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Load a project declaration from the first file, if the cwd had none',
  callback = function()
    local name = project_declared and '' or vim.api.nvim_buf_get_name(0)
    local found = name ~= ''
      and vim.fs.find('.nvim.lua', { path = vim.fs.dirname(name), upward = true })[1]
    local contents = found and vim.secure.read(found)
    if not contents then return end
    local chunk, err = load(contents, '@' .. found)
    if not chunk then return vim.notify(err, vim.log.levels.ERROR) end
    local ok, run_err = pcall(chunk)
    if not ok then vim.notify(run_err, vim.log.levels.ERROR) end
  end,
})

-- [[ Plugins ]]
-- Managed by Neovim's built-in plugin manager, `:help vim.pack`.
--  :lua vim.pack.update()                -- update all, review, `:w` to confirm
--  :lua vim.pack.update({ 'fzf-lua' })   -- update just one
--  :lua vim.pack.update(nil, { offline = true })  -- just list what's installed
-- The lockfile lives next to this file as `nvim-pack-lock.json`; commit it.

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

    -- Redundant since 0.11 -- Neovim sets this exact mapping itself on
    -- LspAttach. Kept deliberately, as a visible reminder that it exists.
    -- See `:help K` and `:help lsp-defaults`.
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
