vim.opt.hidden = true
vim.opt.expandtab = true
vim.opt.mouse = 'a'

-- New sp windows open right or bottom
vim.opt.splitbelow = true
vim.opt.splitright = true

-- persistent undo
vim.opt.undodir = '~/.config/nvim/undo'
vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undoreload = 10000

-- make backspace work in insert mode
vim.opt.backspace = { 'indent', 'eol', 'start' }

-- better line wrap
vim.opt.showbreak = '…'

-- highlight stuff
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- case insensitive search, except when using capital letters
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- custom statusline
vim.opt.statusline = '%t' -- file name
--vim.opt.statusline += '%10y' -- type of file, padded 10 spaces
vim.opt.statusline = vim.opt.statusline + '%5m' -- modified marker
vim.opt.statusline = vim.opt.statusline + '%=' -- align right
vim.opt.statusline = vim.opt.statusline + '%-4c' -- column
vim.opt.statusline = vim.opt.statusline + '%l/%L' -- display line / total lines

-- reload files changed outside of nvim
vim.opt.autoread = true

vim.opt.scrolloff = 5

vim.opt.showcmd = true

vim.opt.showmatch = true
vim.opt.matchpairs = "(:),{:},[:],<:>"

