-- [[ Project tasks ]]
-- require()'d from init.lua for its side effects: this file defines the global
-- Project(), the tasks it turns into commands, and the two :Project commands
-- that exist without a declaration. It returns nothing.
--
-- A project declares the commands it runs in a `.nvim.lua` at its root -- see
-- Project() in the second half of this file; everything generic lives here so
-- that file stays a plain declaration. 'exrc' is what loads it: it searches the
-- cwd and every parent directory, and `:trust` gates it so a repo you have just
-- cloned cannot run code at you. See `:help 'exrc'`.
--
-- A repo we cannot commit to keeps the same declaration in this config instead,
-- as `projects/<its directory name>.lua` -- see load_stored() further down.
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

-- Set while a declaration held in this config rather than in the project is
-- running -- see load_stored() below. The file is not at the root it describes,
-- so the root cannot be inferred from it.
local stored_root

function Project(spec)
  if project_declared then return end
  project_declared = true

  -- The root is the directory of whatever called us, i.e. the `.nvim.lua`
  -- itself: stack level 2, with `@` marking a real filename.
  local source = debug.getinfo(2, 'S').source
  project_root = stored_root
    or (source:sub(1, 1) == '@' and vim.fs.dirname(source:sub(2)))
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

-- Some repos are not ours to put a `.nvim.lua` in -- a work checkout carries it
-- as an untracked file, and a reclone or `git clean -xdf` takes it with them.
-- Those keep their declaration in this config instead, as
-- `<stdpath('config')>/projects/<the repo's directory name>.lua`, holding the
-- same `Project({ ... })` call and/or `vim.g` settings a `.nvim.lua` would.
--
-- Keyed on the directory name rather than the remote so it costs no subprocess
-- at startup, and so two clones of one repo can be configured apart. `.git` is
-- what marks the root, since there is no declaration file to mark it here.
--
-- No `:trust` is involved: that gate is for code arriving from outside, and
-- this is our own config. Nor is 'exrc' -- we load it ourselves, at require
-- time, which is what makes it usable for `vim.g.roslyn_solution`: the VimEnter
-- fallback below already runs after the LSP client has initialised.
local function load_stored(from)
  local root = vim.fs.root(from, '.git')
  if not root then return end
  local path = vim.fs.joinpath(vim.fn.stdpath('config'), 'projects',
    vim.fs.basename(root) .. '.lua')
  if not vim.uv.fs_stat(path) then return end

  stored_root = root
  local ok, err = pcall(dofile, path)
  stored_root = nil
  if not ok then
    vim.notify(('Project: %s: %s'):format(path, err), vim.log.levels.ERROR)
  end
end

-- A `.nvim.lua` in the repo wins, so only look when the upward search finds
-- none. Search from the first file's directory rather than the cwd where there
-- is one: unlike 'exrc' this is not tied to where nvim was started, so
-- `nvim ~/projects/foo/src/x.cs` from elsewhere still gets the declaration.
do
  local from = assert(vim.uv.cwd())
  local first = vim.fn.argv(0)
  if first ~= '' then
    -- `nvim ~/projects/foo` opens a directory, and its dirname is the parent.
    local path = vim.fn.fnamemodify(first, ':p')
    from = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
  end
  if not vim.fs.find('.nvim.lua', { path = from, upward = true })[1] then
    load_stored(from)
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
