" Mark Youngman's Neovim Settings
" Last change:	07 Feb 2018

" vim-plug
call plug#begin('~/.config/nvim/plugged')

Plug 'easymotion/vim-easymotion'
Plug 'ludovicchabant/vim-gutentags'

Plug 'scrooloose/nerdtree'
noremap <C-n> :NERDTreeToggle<CR>

"Plug 'sirver/ultisnips'
"Plug 'justmao945/vim-clang'

"Plug 'mfukar/robotframework-vim'

call plug#end()

" set color scheme
colorscheme desert
"colorscheme altdesert

"set encoding=utf-8 

" Make backspace work in insert mode
set backspace=indent,eol,start

" Switch syntax highlighting on
syntax on

" Switch off network history
let g:netrw_dirhistmax = 0

" Convenient cursor movement
nnoremap <C-k> {
nnoremap <C-j> }
nnoremap <C-h> ^
nnoremap <C-l> $

" Copy to end of line
noremap Y y$

" Easier completion
inoremap <C-Space> <C-x><C-]>

" macros
" @a adds curly brackets below and puts cursor inside them in insert mode
let @a = 'o{o}O i'

" Use space as leader key
let mapleader = "\\"
"let g:mapleader = "\\"

nnoremap <leader>w :update<cr>
nnoremap <leader>q :qall<cr>
nnoremap <leader>c :close<cr>

" Surround word with "/</(
nnoremap <leader>" viw<esc>a"<esc>hbi"<esc>lel
nnoremap <leader>< viw<esc>a><esc>hbi<<esc>lel
nnoremap <leader>( viw<esc>a)<esc>hbi(<esc>lel
"Test: flkjal alfkjalf lajslkf

" Add {}
inoremap <leader>{ <space>{<esc>o}<esc>O
"nnoremap <leader>{ o{<esc>o}<esc>O<esc>

" Quick way to open and load init.vim
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" C&P to clipboard
nnoremap <leader>y "+y
nnoremap <leader>p "+p
" Because 'd' also copies:
nnoremap <leader>P "0p

" session make and restore
nnoremap <leader>m :mksession!<cr>
nnoremap <leader>. :source Session.vim<cr>

" persistent undo
set undodir=~/.config/nvim/undo/
set undofile
set undolevels=1000
set undoreload=10000

" new sp windows open right or bottom
set splitbelow
set splitright

" open vsp window at startup
"au VimEnter * vsplit

" Compile and Quickfix Stuff
set makeprg=./build.sh
nnoremap <F12> :silent w<cr>:silent make<cr>:silent cwindow<cr>:silent cc<cr>

" mappings for quickfix window
nnoremap <leader>j :cnext<cr>
nnoremap <leader>k :cprevious<cr>
nnoremap <leader>l :cclose<cr>

" better line wrap
set showbreak=↪

" Find the next match as we search
set incsearch

" highlight search words, ESC to switch off hl
set hlsearch
nnoremap <ESC> :nohl<CR><ESC>
" no highlight after reloading $MYVIMRC
nohl

" case insensitive search, except when using capital letters
set ignorecase
set smartcase

" Custom statusline
set statusline=%f "path to file
"set statusline+=%10y "type of file, padded 10 spaces
set statusline+=%5m "modified marker
set statusline+=%= "move to right side
set statusline+=%-4c "column
set statusline+=%l/%L "display line/total lines

set autoindent
"set smartindent
"filetype plugin indent on

" Reload file changed outside nvim
set autoread

"C indentation options
set cindent
"set cinoptions=g1,h1,N-s
set cinoptions+=(0

" Show syntax highlighting groups for word under cursor
"nnoremap <C-S-P> :call <SID>SynStack()<CR>
"function! <SID>SynStack()
"if !exists("*synstack")
"return
"endif
"echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
"endfunc

" Tab stuff
set shiftwidth=3
set tabstop=3
set softtabstop=3
set expandtab
set smarttab

" Scroll 8 lines before the bottom
set scrolloff=8

" Keep backups of files
set backup
set backupdir=~/.config/nvim/backup/

" show cmds in bottom right
set showcmd

" better tab when using commands
set wildmenu

" Show matching brackets
set showmatch
set matchpairs+=<:>

" show line numbers
set number
set numberwidth=4

" if gui running, remove gui menu and toolbar and scroll bars
"if has('gui_running')
"set guioptions-=m
"set guioptions-=T
"set guioptions-=r
"set guioptions-=L
"endif

" ****
" Windows GUI tweaks
" ****
"if has("gui_win32")
"set guifont =DejaVu_Sans_Mono:h9:cANSI
"autocmd GUIEnter * :simalt ~x
" set shellslash
"endif

" THIS CAUSES A BUG IN NEOVIM? " maximise gvim window at startup
"set lines=99 columns=999

" make visualbell so it does nothing (accompanied by line in gvimrc to stop
" screen flashing on error)
set noerrorbells visualbell t_vb=

"set dir of ctags utility (not plugin folder)
"if has("win32")
"  let Tlist_Ctags_Cmd = "C:\Users\Mark\vimfiles\ctags.exe"
"endif
