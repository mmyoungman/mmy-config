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
-- A project declares the commands it runs in a `.nvim.lua` at its root -- see
-- Project() at the end of this section; everything generic lives here so that
-- file stays a plain declaration. 'exrc' is what loads it: it searches the cwd
-- and every parent directory, and `:trust` gates it so a repo you have just
-- cloned cannot run code at you. See `:help 'exrc'`.
vim.o.exrc = true

-- The directory holding the `.nvim.lua`. Every task runs from here, and it is
-- what relative paths in a task's output are resolved against. nil until a
-- declaration loads, at which point the task commands come into existence too.
local project_root

-- One quickfix task at a time -- they all write the same list. Terminal tasks
-- are unaffected: each owns a window, so they cannot trample each other.
local task_running = false
local task_name = nil                -- which task, so a clash can name it
local task_handle = nil              -- the vim.system object of the running task
local task_cancel_requested = false

-- The quickfix list is only a *view* of a task: 'errorformat' drops every line
-- it does not recognise, so a bash error, a missing tool, or any compiler we
-- have no format for would vanish from it. Keep the raw output of the last task
-- so :ProjectLog can always show exactly what happened.
local last_task = {}

-- Tasks are async, so C-c in the UI cannot reach them: this is the interrupt.
-- A task runs detached -- a process-group leader -- so the negative-pid signal
-- reaches the whole group: a script that spawned children of its own cannot
-- outlive the stop by holding the output pipe open.
vim.api.nvim_create_user_command('ProjectStop', function()
  if not task_running or not task_handle then
    return vim.notify('No task is running', vim.log.levels.WARN)
  end
  task_cancel_requested = true
  pcall(vim.uv.kill, -task_handle.pid, 'sigterm')
  task_handle:kill('sigterm')
end, { desc = 'Kill the running project task' })

-- `:make` does all of this already, but synchronously -- it freezes the UI
-- until the compiler exits. vim.system() runs the task in the background;
-- 'errorformat' still does the parsing, via setqflist()'s `efm`.
local function run_quickfix(name, cmd, task)
  if task_running then
    return vim.notify(('Task %q is already running'):format(task_name),
      vim.log.levels.WARN)
  end
  -- No efm declared falls back to the default 'errorformat', which already
  -- reads `src/foo.c:12:5: msg` and make's Entering/Leaving directory lines.
  -- Read vim.o, never vim.bo: 'errorformat' is |global-local|, and an
  -- ftplugin's buffer-local value would otherwise make the same task mean
  -- different things depending on which buffer you happened to be in.
  local efm = task.efm or vim.o.errorformat

  -- last_task is deliberately left alone until this one finishes: starting a
  -- build should not wipe the :ProjectLog you were still reading.
  task_running = true
  task_name = name
  task_cancel_requested = false
  vim.notify(('%s: %s'):format(name, cmd))
  -- Merge stderr into stdout in the shell, rather than concatenating the two
  -- captured strings afterwards: concatenating puts every stderr line after
  -- every stdout line, and 'errorformat' is order-sensitive -- its %D/%X
  -- "Entering/Leaving directory" directives can only track the compiler's cwd
  -- against genuinely interleaved output. `:make` merges for the same reason,
  -- via 'shellpipe' (`2>&1| tee`). The subshell keeps the redirect applied to
  -- the whole command, not just the last stage of a `&&` chain. The `cd` goes
  -- here rather than into the declared command so that every message, quickfix
  -- title and :ProjectLog header shows what you actually wrote.
  local shell_cmd = ('cd %s && (%s) 2>&1')
    :format(vim.fn.shellescape(project_root), cmd)
  -- pcall: if the spawn itself fails, undo the running flag rather than wedging
  -- every task until restart. `detach` makes the shell a process-group leader,
  -- which is what lets :ProjectStop signal the whole group.
  local ok, handle_or_err = pcall(vim.system,
    { vim.o.shell, vim.o.shellcmdflag, shell_cmd },
    { text = true, detach = true }, function(res)
    vim.schedule(function()
      task_running = false
      task_handle = nil
      local output = res.stdout or ''
      -- A killed process reports a signal rather than a meaningful exit code.
      -- res.signal is a number: 0 on a normal exit, the signum otherwise;
      -- report our own stop request (or an external SIGTERM) as a
      -- cancellation, not a failure.
      local cancelled = task_cancel_requested or (res.signal or 0) ~= 0
      last_task = { name = name, cmd = cmd, code = res.code, output = output }

      -- setqflist() resolves relative filenames against the cwd at the moment
      -- the list is built, and the task ran from the project root. A compiler
      -- given `src/foo.c`, or a test printing `tests/bar.c:41`, therefore
      -- reports paths relative to the root, not to wherever nvim happened to be
      -- started -- so parse from there. While still sitting in the root,
      -- rewrite every parsed filename to an absolute path: relative ones would
      -- otherwise resolve against the cwd of whichever window you jump
      -- (<leader>j/k) *from*, which is often not the root. pcall guards the
      -- whole dance -- a bad 'errorformat' must not leave your window silently
      -- cd'd into the project.
      local previous = vim.fn.chdir(project_root)
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
      -- closes it if not, so a clean task just quietly succeeds.
      vim.cmd('cwindow')

      -- Lines 'errorformat' did *not* match are still added to the list, as
      -- entries with valid=0, so a non-empty list does not mean the task
      -- produced anything jumpable -- count the valid ones. A non-zero exit is
      -- always reported, even when there are errors in quickfix, because the
      -- interesting failure is often the one that did not parse: `bear: command
      -- not found` next to three real compile errors. When nothing parsed at
      -- all, the raw output goes straight into the message.
      local qf = vim.fn.getqflist()
      local matched = #vim.tbl_filter(function(e) return e.valid == 1 end, qf)
      if cancelled then
        return vim.notify(
          ('%s cancelled: %d entries kept. :ProjectLog for raw output')
            :format(name, matched),
          vim.log.levels.WARN
        )
      end
      if res.code ~= 0 then
        local msg = ('%s failed (exit %d): %d in quickfix, %d unparsed. :ProjectLog for raw output')
          :format(name, res.code, matched, #qf - matched)
        vim.notify(
          matched == 0 and (msg .. '\n' .. vim.trim(output)) or msg,
          vim.log.levels.ERROR
        )
      else
        -- An exit code is only as honest as the script that returns it. A shell
        -- script whose last statement is an untaken `if` exits 0 no matter how
        -- the compiler fared, so a clean exit sitting next to parsed errors
        -- means the failure got swallowed on the way out. Trust 'errorformat'
        -- over the exit code here and say so, rather than letting a broken
        -- build pass for a quiet success. A task that only warns, though, did
        -- genuinely succeed, so grade the entries first.
        --
        -- %t stores the compiler's severity character verbatim, in whatever
        -- case it printed it ('e' from "error:", 'w' from "warning:"), and is
        -- empty for a format carrying no severity at all. So count the explicit
        -- errors -- but if nothing in the list was graded, as with the default
        -- 'errorformat' or a custom `FAIL %f:%l %m` where every match is a
        -- failure by construction, fall back to the whole list rather than
        -- going quiet on a format we cannot read severities from.
        local function count(predicate)
          return #vim.tbl_filter(function(e) return e.valid == 1 and predicate(e) end, qf)
        end
        local errors = count(function(e) return e.type:lower() == 'e' end)
        local graded = count(function(e) return e.type ~= '' end) > 0
        local suspect = errors > 0 and errors or (graded and 0 or matched)
        if suspect > 0 then
          vim.notify(
            ('%s exited 0 but %d error(s) parsed -- exit code likely swallowed by the script')
              :format(name, suspect),
            vim.log.levels.WARN
          )
        end
      end
      -- Unlike sync :make there is no automatic jump: this fires while you may
      -- be typing. A task that wants :make's behaviour declares `jump = true`.
      if matched > 0 and task.jump then vim.cmd('cc 1') end
    end)
  end)
  if not ok then
    task_running = false
    return vim.notify(('%s failed to start: %s'):format(name, handle_or_err),
      vim.log.levels.ERROR)
  end
  task_handle = handle_or_err
end

-- Running a program is not the same problem as building one: you usually want
-- to watch it and type at it, not scrape its stderr. So `term = true` gets a
-- terminal split instead. To chase a `file.c:42:` in its log, `gF` on the
-- reference jumps straight there; <leader>cq instead pushes the whole log
-- through 'errorformat' into quickfix, so <leader>j / <leader>k walk the
-- references.
local run_buf                        -- terminal of the current run; exactly one

local function run_terminal(cmd, task)
  -- One run slot: kill the previous program and clear it out, so the mapping is
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
  -- `lcd` *before* `:terminal`, not after: the job inherits the window's cwd at
  -- spawn time. That gives the program the project root to run from, and gives
  -- the window the same root to resolve the paths it logs -- a C program's
  -- __FILE__ is the path the compiler was given ("src/rules.c"), relative to
  -- the root, not to wherever nvim was started.
  vim.cmd('botright split')
  vim.cmd('lcd ' .. vim.fn.fnameescape(project_root))
  vim.cmd('terminal ' .. cmd)
  run_buf = vim.api.nvim_get_current_buf()
  -- The task's own 'errorformat' rides on the terminal buffer, so <leader>cq
  -- parses the program's log format rather than a compiler's -- a line like
  -- "[ERROR] (src/game.c:12) oops" matches no compiler format at all.
  if task.efm then vim.bo.errorformat = task.efm end
  -- Output is only "tailed" while the cursor is on the last line (`:help
  -- terminal`). A terminal opens in Normal mode with the cursor at the top,
  -- where it stays, so the view falls behind as soon as the program prints more
  -- than a screenful. Parking the cursor on the last line makes it follow. Note
  -- this stays in Normal mode on purpose -- `startinsert` would tail too, but
  -- then keystrokes go to the program and gF / <leader>cq stop working without
  -- first escaping terminal-mode.
  vim.cmd('normal! G')
end

local function run_task(name, task, args)
  vim.cmd('silent! wall')
  -- expandcmd() does the `%`/`#` expansion that :make would have done.
  local cmd = vim.fn.expandcmd(args ~= '' and (task[1] .. ' ' .. args) or task[1])
  if task.term then run_terminal(cmd, task) else run_quickfix(name, cmd, task) end
end

-- The unfiltered truth about the last task, for when quickfix looks wrong or
-- suspiciously empty. `gF` jumps to any file:line in here too, and `:cbuffer`
-- re-parses the whole thing into quickfix. A `term = true` task is not recorded
-- here: its terminal buffer already *is* the raw log.
vim.api.nvim_create_user_command('ProjectLog', function()
  if not last_task.cmd then
    return vim.notify('No task has finished yet', vim.log.levels.WARN)
  end
  vim.cmd('botright new')
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile = 'nofile', 'wipe', false
  -- Same treatment as a terminal task: paths in the log are relative to the
  -- project root, so give this window that cwd for gF and :cbuffer.
  vim.cmd('lcd ' .. vim.fn.fnameescape(project_root))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(
    ('$ %s\n[%s exited %d]\n\n%s')
      :format(last_task.cmd, last_task.name, last_task.code, last_task.output),
    '\n'))
  vim.bo[buf].modified = false
end, { desc = 'Raw output of the last project task' })

vim.api.nvim_create_autocmd('TermOpen', {
  desc = 'Let a terminal log be sent to the quickfix list',
  callback = function(event)
    vim.keymap.set('n', '<leader>cq', '<Cmd>cbuffer<CR><Cmd>cwindow<CR>',
      { buffer = event.buf, desc = 'Terminal output -> [q]uickfix' })
  end,
})

vim.keymap.set('n', '<leader>xl', '<Cmd>ProjectLog<CR>', { desc = 'Task [l]og' })
vim.keymap.set('n', '<leader>xs', '<Cmd>ProjectStop<CR>', { desc = '[S]top task' })

-- [[ Project declarations ]]
-- A project's `.nvim.lua` should be a declaration and nothing more:
--
--     Project({
--       build = './build_linux.sh',              -- :ProjectBuild  <leader>xb
--       wasm  = './build_wasm.sh',               -- :ProjectWasm   <leader>xw
--       test  = { './build_tests.sh',            -- :ProjectTest   <leader>xt
--                 efm = 'FAIL %f:%l %m,%-GPASS %.%#' },
--       run   = { './build_linux.sh --run',      -- :ProjectRun    <leader>xr
--                 term = true, efm = '[%t%*[A-Z]] (%f:%l) %m' },
--     })
--
-- Every key is optional and none of them is special: a key becomes
-- :ProjectKey, bound to <leader>x plus its first letter. A dependency with
-- nothing but a test suite declares `test` alone and gets exactly
-- :ProjectTest -- no :ProjectBuild falling back to a `make` the repo has no
-- makefile for, and no :ProjectRun that only errors when you press it. The
-- flip side is that <leader>xb is not stable across projects; it is whatever
-- that project called its b-task, if it has one.
--
-- An entry is a command string, or a table of one plus options:
--
--   efm   the 'errorformat' for this command's output. This is per command on
--         purpose: a compiler, a test runner and the program's own log are
--         three different formats, and a build's format will not match a line
--         like "[ERROR] (src/game.c:12) oops". Omitted, the default
--         'errorformat' applies, which already reads `src/foo.c:12:5: msg` and
--         make's Entering/Leaving directory lines -- though it carries no
--         severity, so a task that emits warnings wants %trror:/%tarning:
--         patterns of its own to stay clear of the exit-code check above.
--   term  run in a terminal split instead of the quickfix list, for a program
--         you want to watch and type at rather than scrape.
--   jump  jump to the first error, the way :make does.
--
-- Everything runs from the project root -- the directory holding the
-- `.nvim.lua` -- because build scripts routinely refuse to run anywhere else,
-- and 'exrc' searching upwards means nvim is often started in a subdirectory.
-- Arguments append, so `:ProjectBuild --release` needs no key of its own.

-- <leader>x letters that are not up for grabs, because they drive the two
-- commands that exist with or without a declaration.
local reserved_letters = { l = ':ProjectLog', s = ':ProjectStop' }

-- 'exrc' does not stop at the first `.nvim.lua` it finds: it loads the nearest
-- one and then keeps walking up, so in a monorepo the repo-root file runs
-- *last* and would clobber the sub-project's. Nearest-wins instead -- the first
-- declaration sticks and later (outer) ones are ignored, so
-- `frontend/.nvim.lua` beats the root when you are working in frontend/.
local project_declared = false

function Project(spec)
  if project_declared then return end
  project_declared = true

  -- The root is the directory of whatever called us, i.e. the `.nvim.lua`
  -- itself: stack level 2, with `@` marking a real filename.
  local source = debug.getinfo(2, 'S').source
  project_root = source:sub(1, 1) == '@' and vim.fs.dirname(source:sub(2))
    or assert(vim.uv.cwd())

  -- Project() runs while 'exrc' sources, before the UI has settled, where a
  -- plain notify is easily lost behind the intro screen.
  local function reject(fmt, ...)
    local msg = ('Project: ' .. fmt):format(...)
    vim.schedule(function() vim.notify(msg, vim.log.levels.ERROR) end)
  end

  -- Sorted rather than pairs(): the order is otherwise random, so which of two
  -- clashing keys is the one reported would change between starts. Non-string
  -- keys are dropped before sorting rather than after -- `Project({ './b.sh' })`
  -- with the name forgotten yields a number key, and table.sort() throws
  -- outright on comparing one of those to a string.
  local keys = {}
  for key in pairs(spec) do
    if type(key) == 'string' then
      keys[#keys + 1] = key
    else
      reject('entry %s ignored -- every task needs a name, as in '
        .. 'build = \'./script.sh\'', vim.inspect(key))
    end
  end
  table.sort(keys)

  local taken = vim.tbl_extend('force', {}, reserved_letters)
  for _, key in ipairs(keys) do
    -- A bare string is the command; a table is the command plus its options.
    local task = type(spec[key]) == 'table' and spec[key] or { spec[key] }
    local letter = key:sub(1, 1):lower()
    -- One offending key is skipped rather than aborting the declaration: a typo
    -- in `wasm` must not cost you `build` as well.
    if not key:match('^%a%w*$') then
      reject('key %q ignored -- a key must start with a letter and contain only '
        .. 'letters and digits, so that it can name a command (:help E182)', key)
    elseif type(task[1]) ~= 'string' or task[1] == '' then
      reject('key %q ignored -- it needs a command, either %s = \'./script.sh\' '
        .. 'or %s = { \'./script.sh\', efm = ... }', key, key, key)
    elseif taken[letter] then
      reject('key %q ignored -- the letter %q is already taken by %s '
        .. '(<leader>x%s). Every key needs a unique first letter.',
        key, letter, taken[letter], letter)
    else
      taken[letter] = ('%q'):format(key)
      local name = 'Project' .. key:sub(1, 1):upper() .. key:sub(2)
      vim.api.nvim_create_user_command(name, function(opts)
        run_task(key, task, opts.args)
      end, { nargs = '*', desc = task[1] })
      vim.keymap.set('n', '<leader>x' .. letter, '<Cmd>' .. name .. '<CR>',
        { desc = key .. ': ' .. task[1] })
    end
  end
end

-- 'exrc' searches the *cwd* and its parents, not the file you opened, so
-- `nvim ~/projects/foo/src/x.c` from somewhere else gets no project at all: no
-- task commands exist and nothing is bound under <leader>x. Search upward from
-- the first file as well. vim.secure.read() applies the same `:trust` gate
-- 'exrc' does, and naming the chunk `@<path>` keeps debug.getinfo() in
-- Project() pointing at the real file.
vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Load a project declaration from the first file, if the cwd had none',
  callback = function()
    if project_declared then return end
    -- Search from the first file's directory, falling back to the cwd so that a
    -- bare `nvim` inside a project still reports an untrusted declaration below
    -- rather than looking inexplicably featureless.
    local name = vim.api.nvim_buf_get_name(0)
    local from = name ~= '' and vim.fs.dirname(name) or assert(vim.uv.cwd())
    local found = vim.fs.find('.nvim.lua', { path = from, upward = true })[1]
    if not found then return end
    -- Distinguish "no declaration anywhere" from "found one you have not
    -- trusted". The second is silent otherwise, and looks identical to a broken
    -- config: no commands, nothing under <leader>x, no clue why. Editing a
    -- trusted `.nvim.lua` invalidates its stored hash, so this is the normal
    -- state after any change to it, not an exotic one.
    local contents = vim.secure.read(found)
    if not contents then
      return vim.notify(
        ('%s is not trusted, so no project tasks were loaded. Open it and :trust')
          :format(vim.fn.fnamemodify(found, ':~')),
        vim.log.levels.WARN
      )
    end
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
