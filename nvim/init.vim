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
"function! IsNERDTreeOpen()
"  return exists("t:NERDTreeBufName") && (bufwinnr(t:NERDTreeBufName) != -1)
"endfunction
"function! SyncTree()
"  if &modifiable && IsNERDTreeOpen() && strlen(expand('%')) > 0 && !&diff
"    NERDTreeFind
"    wincmd p
"  endif
"endfunction
"autocmd BufEnter * call SyncTree()

" FZF
silent! noremap <C-p> :GFiles<CR>

" Coc
let g:coc_global_extensions = [
  \ 'coc-tsserver',
  \ 'coc-eslint',
  \ 'coc-prettier',
  \ 'coc-omnisharp',
  \ 'coc-python',
  \ ]
set shortmess+=c
set signcolumn=yes
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

nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> <leader>rn <Plug>(coc-rename)

" Highlight line after cursor jump
function s:Cursor_Moved()
  let cur_pos = winline()
  if g:last_pos == 0
    set cul
    let g:last_pos = cur_pos
    return
  endif
  let diff = g:last_pos - cur_pos
  if diff > 1 || diff < -1
    set cul
  else
    set nocul
  endif
  let g:last_pos = cur_pos
endfunction
autocmd CursorMoved,CursorMovedI * call s:Cursor_Moved()
let g:last_pos = 0

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

" Scroll 8 lines before the bottom
set scrolloff=8

" Keep backups of files
" Or not because of Coc/Language servers
set nobackup
set nowritebackup
"silent !mkdir -p ~/.config/nvim/backup
"set backup
"set backupdir=~/.config/nvim/backup/

" show cmds in bottom right
set showcmd

" Show matching brackets
set showmatch
set matchpairs+=<:>

" show line numbers
set number
set numberwidth=4

" nvim-qt
if exists('g:GuiLoaded')
GuiPopupmenu 0
endif
set noerrorbells visualbell t_vb=
