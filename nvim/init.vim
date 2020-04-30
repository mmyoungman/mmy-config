" Mark Youngman's Neovim Settings

" pip install neovim
" npm install -g neovim

call plug#begin('~/.config/nvim/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'scrooloose/nerdtree'

Plug 'easymotion/vim-easymotion'
Plug 'junegunn/fzf', {
  \ 'do':'./install --all'
  \ }
Plug 'junegunn/fzf.vim'
Plug 'HerringtonDarkholme/yats.vim'  "TS syntax highlighting

call plug#end()

set hidden

" Nerdtree
noremap <leader>n :NERDTreeToggle<CR>
let g:NERDTreeIgnore = ['^node_modules$']
" sync open file with NERDTree
function! IsNERDTreeOpen()        
  return exists("t:NERDTreeBufName") && (bufwinnr(t:NERDTreeBufName) != -1)
endfunction
function! SyncTree()
  if &modifiable && IsNERDTreeOpen() && strlen(expand('%')) > 0 && !&diff
    NERDTreeFind
    wincmd p
  endif
endfunction
autocmd BufEnter * call SyncTree()

" FZF
silent! noremap <C-p> :GFiles<CR>

" Coc
let g:coc_global_extensions = [
  \ 'coc-tsserver',
  \ 'coc-eslint',
  \ 'coc-prettier',
  \ 'coc-json',
  \ 'coc-omnisharp',
  \ 'coc-python',
  \ ]
silent! noremap <leader>i :silent CocCommand prettier.formatFile<CR>
inoremap <silent><expr> <C-Space> coc#refresh()
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

nnoremap <silent> [g <Plug>(coc-diagnostic-prev)
nnoremap <silent> ]g <Plug>(coc-diagnostic-next)
nnoremap <silent> gd <Plug>(coc-definition)
nnoremap <silent> gy <Plug>(coc-type-definition)
nnoremap <silent> gi <Plug>(coc-implementation)
nnoremap <silent> gr <Plug>(coc-references)

"let s:uname = system("uname -s")
"if s:uname == "Linux"
"   let g:deoplete#sources#clang#libclang_path = '/usr/lib/libclang.so'
"   let g:deoplete#sources#clang#clang_header = '/usr/lib/clang'
"endif
"if s:uname == "Darwin" " macOS
"endif

" set color scheme
colorscheme desert

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

" Quick way to open and load init.vim
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" Use backslash as leader key
let mapleader = "\\"
"let g:mapleader = "\\"

" Convenient cursor movement
nnoremap <C-k> {
nnoremap <C-j> }
vnoremap <C-k> {
vnoremap <C-j> }
nnoremap <C-h> ^
nnoremap <C-l> $

" Copy to end of line, to match behaviour of D and C
nnoremap Y y$

" Since insert mode C-h is backspace, C-l should delete char infront
inoremap <C-l> <del>

" Surround word with " or < or (
nnoremap <leader>" viw<esc>a"<esc>hbi"<esc>lel
nnoremap <leader>' viw<esc>a'<esc>hbi'<esc>lel
nnoremap <leader>< viw<esc>a><esc>hbi<<esc>lel
nnoremap <leader>( viw<esc>a)<esc>hbi(<esc>lel
"Test: flkjal alfkjalf lajslkf

" Cut and paste to system clipboard
vnoremap <leader>y "+y
nnoremap <leader>p "+p
nnoremap <leader>P "+P

" New sp windows open right or bottom
set splitbelow
set splitright

" Compile and Quickfix Stuff
set makeprg=./build.sh
"set compiler=somethingorother
nnoremap <F12> :silent w<cr>:silent make<cr>:silent cwindow<cr>:silent cc<cr>

" Mappings for quickfix window
nnoremap <leader>j :cnext<cr>
nnoremap <leader>k :cprevious<cr>
nnoremap <leader>l :cclose<cr>

" Better line wrap
set showbreak=…

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

"set autoindent " screws with python indentation?
"set smartindent
"filetype plugin indent on

" Reload file changed outside nvim
set autoread

"C indentation options
"set cindent
"set cinoptions=g1,h1,N-s
"set cinoptions+=(0

" Tab stuff
set shiftwidth=2
set tabstop=2
set softtabstop=2
set expandtab
"set smarttab

" Scroll 8 lines before the bottom
set scrolloff=8

" Keep backups of files
silent !mkdir -p ~/.config/nvim/backup
set backup
set backupdir=~/.config/nvim/backup/

" show cmds in bottom right
set showcmd

" better tab when using commands
"set wildmenu

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
