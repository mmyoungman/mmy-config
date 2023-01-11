-- :help options
local defaultOptions = {
  hidden = true,
  expandtab = true,
  shiftwidth = 2,
  tabstop = 2,
  showtabline = 2,
  mouse = 'a',

  splitbelow = true,
  splitright = true,

  -- bug when you use ~ which ends in creation of '~' dir? because of my symlinked nvim dir?
  undodir = '/home/mark/.config/nvim/undo',

  undofile = true,
  undolevels = 1000,
  undoreload = 10000,

  backspace = { 'indent', 'eol', 'start' },

  showbreak = '…',

  incsearch = true,
  hlsearch = true,

  backup = false,
  writebackup = false,
  --vim.cmd('!mkdir -p ~/.config/nvim/backup', { silent = true })
  --vim.opt.backup = true
  --vim.opt.backupdir = '~/.config/nvim/backup/'
  --
  ignorecase = true,
  smartcase = true,

  autoread = true,
  scrolloff = 5,

  showcmd = true,
  showmatch = true,

  matchpairs = "(:),{:},[:],<:>",
}

vim.opt.statusline = '%f' -- file name
vim.opt.statusline:append '%5m' -- modified marker
vim.opt.statusline:append '%=' -- align right
vim.opt.statusline:append '%-4c' -- column
vim.opt.statusline:append '%l/%L' -- display line / total lines

for key, value in pairs(defaultOptions) do
  vim.opt[key] = value
end
