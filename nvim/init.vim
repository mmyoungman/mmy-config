" Mark Youngman's Neovim Settings

" vim-plug for plugins
" :PlugInstall on a new install
call plug#begin('~/.config/nvim/plugged')

Plug 'easymotion/vim-easymotion'
Plug 'ludovicchabant/vim-gutentags'
Plug 'tpope/vim-fugitive'

" Need "pip install jedi" for this
Plug 'davidhalter/jedi-vim'

Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'zchee/deoplete-jedi'

Plug 'zchee/deoplete-clang'

"Plug 'scrooloose/nerdtree'
"noremap <leader>n :NERDTreeToggle<CR>

"Plug 'sirver/ultisnips'
"Plug 'justmao945/vim-clang'

" For robot framework syntax highlighting and tags
"Plug 'mfukar/robotframework-vim'
"Plug 'mMontu/vim-RobotUtils'

" Plugins to experiement with
"Plug 'bling/vim-airline'

call plug#end()

" Let deoplete-jedi handle completion for python
let g:jedi#completions_enabled = 0

" Deoplete stuff
let g:deoplete#enable_at_startup = 1

let s:uname = system("uname -s")
if s:uname == "Linux"
   let g:deoplete#sources#clang#libclang_path = '/usr/lib/libclang.so'
   let g:deoplete#sources#clang#clang_header = '/usr/lib/clang'
endif
"if s:uname == "Darwin" " macOS
"endif

" set color scheme
colorscheme desert
"colorscheme altdesert

" Switch syntax highlighting on
syntax on

"set encoding=utf-8 

" persistent undo
silent !mkdir -p ~/.config/nvim/undo
set undodir=~/.config/nvim/undo/
set undofile
set undolevels=1000
set undoreload=10000

" Make backspace work in insert mode
set backspace=indent,eol,start

" No auto insert comments on new line
autocmd FileType * set formatoptions-=cro

" Jump to definition in vertical split, but not a new split
"nnoremap <C-]> :execute "vertical ptag " . expand("<cword>")<cr><C-w>=

" Switch off network history
let g:netrw_dirhistmax = 0

" Convenient cursor movement
nnoremap <C-k> {
nnoremap <C-j> }
vnoremap <C-k> {
vnoremap <C-j> }
nnoremap <C-h> ^
nnoremap <C-l> $

" Copy to end of line, to match behaviour of D and C
nnoremap Y y$

" Easier completion
inoremap <C-Space> <C-x><C-]>

" Add {}
" macro?
"let @a = 'o{o}O i'
inoremap <leader>{ <space>{<esc>o}<esc>O
nnoremap <leader>{ a<space>{<esc>o}<esc>O

" Use backslash as leader key
let mapleader = "\\"
"let g:mapleader = "\\"

" Surround word with " or < or (
nnoremap <leader>" viw<esc>a"<esc>hbi"<esc>lel
nnoremap <leader>< viw<esc>a><esc>hbi<<esc>lel
nnoremap <leader>( viw<esc>a)<esc>hbi(<esc>lel
"Test: flkjal alfkjalf lajslkf

" Quick way to open and load init.vim
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" Cut and paste to system clipboard
vnoremap <leader>y "+y
nnoremap <leader>p "+p
nnoremap <leader>P "+P

" Session make and restore
nnoremap <leader>m :mksession!<cr>
nnoremap <leader>. :source Session.vim<cr>:!rm Session.vim<cr>

" New sp windows open right or bottom
set splitbelow
set splitright

" Compile and Quickfix Stuff
set makeprg=./build.sh
nnoremap <F12> :silent w<cr>:silent make<cr>:silent cwindow<cr>:silent cc<cr>

" Mappings for quickfix window
nnoremap <leader>j :cnext<cr>
nnoremap <leader>k :cprevious<cr>
nnoremap <leader>l :cclose<cr>

" Better line wrap
set showbreak=↪

" Highlight match while typing search term
set incsearch

" Highlight search words, ESC to switch off hl
set hlsearch
nnoremap <ESC> :nohl<CR><ESC>
" No highlight after reloading $MYVIMRC
nohl

" Case insensitive search, except when using capital letters
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
silent !mkdir -p ~/.config/nvim/backup
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
