" Mark Youngman's Neovim Settings

" pip install neovim
" npm install -g neovim

call plug#begin('~/.config/nvim/plugged')

Plug 'ycm-core/YouCompleteMe'
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
nnoremap <leader>f :NERDTreeToggle<CR>
let g:NERDTreeIgnore = ['^node_modules$']
fun! NERDTreeSync()
  if filereadable(expand('%:p')) && exists('g:NERDTree') && g:NERDTree.IsOpen()
    NERDTreeFind
    wincmd p
  endif
endfun
autocmd BufEnter * call NERDTreeSync()

" FZF
silent! noremap <C-p> :GFiles<CR>

" Completion
let g:coc_global_extensions = [
  \ 'coc-tsserver',
  \ 'coc-eslint',
  \ 'coc-prettier',
  \ 'coc-omnisharp',
  \ 'coc-python',
  \ ]
set shortmess+=c
set signcolumn=yes

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

fun! GoCoc()
  :CocEnable
  noremap <buffer> <silent> <leader>i :CocCommand prettier.formatFile<CR>
  inoremap <buffer> <silent><expr> <C-Space> coc#refresh()
  inoremap <buffer> <silent><expr> <TAB>
        \ pumvisible() ? "\<C-n>" :
        \ <SID>check_back_space() ? "\<TAB>" :
        \ coc#refresh()
  inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

  nmap <buffer> <silent> [g <Plug>(coc-diagnostic-prev)
  nmap <buffer> <silent> ]g <Plug>(coc-diagnostic-next)
  nmap <buffer> <silent> gd <Plug>(coc-definition)
  nmap <buffer> <silent> gy <Plug>(coc-type-definition)
  nmap <buffer> <silent> gi <Plug>(coc-implementation)
  nmap <buffer> <silent> gr <Plug>(coc-references)
  nmap <buffer> <silent> <leader>rn <Plug>(coc-rename)
endfun

fun! GoYCM()
  :CocDisable
  nnoremap <buffer> <silent> gd :YcmCompleter GoTo<CR>
  nnoremap <buffer> <silent> g3 :YcmCompleter GoToReferences<CR>
  nnoremap <buffer> <silent> <leader>rn :YcmCompleter RefactorRename<space>
endfun

"autocmd FileType typescript,cs :call GoYCM()
autocmd FileType typescript,cs :call GoCoc()

let mapleader = "\\"
colorscheme desert
syntax on

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
nnoremap <silent> <F12> :silent w<cr>:silent make<cr>:silent cwindow<cr>:silent cc<cr>

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
nnoremap <silent> <ESC> :nohl<CR><ESC>
" No highlight after reloading $MYVIMRC
nohl

" Case insensitive search, except when using capital letters
set ignorecase
set smartcase

" Custom statusline
set statusline=%t "file name
"set statusline+=%10y "type of file, padded 10 spaces
set statusline+=%5m "modified marker
set statusline+=%= "move to right side
set statusline+=%-4c "column
set statusline+=%l/%L "display line/total lines

" Reload file changed outside nvim
set autoread

" C indentation options
"set cindent
"set cinoptions=g1,h1,N-s
"set cinoptions+=(0

" Tab stuff
set shiftwidth=2
set tabstop=2
set softtabstop=2
set expandtab

" Scroll 8 lines before the bottom
set scrolloff=5

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
