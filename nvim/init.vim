" Mark Youngman's Neovim Settings

call plug#begin('~/.config/nvim/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'scrooloose/nerdtree'
Plug 'easymotion/vim-easymotion'
Plug 'junegunn/fzf', {
  \ 'do':'./install --all'
  \ }
Plug 'junegunn/fzf.vim'
Plug 'HerringtonDarkholme/yats.vim'  "TS syntax highlighting

Plug 'andreyorst/SimpleClangFormat.vim'

call plug#end()

let mapleader = "\\"
colorscheme desert
syntax on
set hidden

" Nerdtree
fun! NERDTreeSync()
  if filereadable(expand('%:p')) && exists('g:NERDTree') && g:NERDTree.IsOpen()
    NERDTreeFind
    wincmd p
  endif
endfun
nnoremap <leader>n :NERDTreeToggle<CR>:wincmd p<CR>:call NERDTreeSync()<CR>
autocmd BufEnter * call NERDTreeSync()
let g:NERDTreeIgnore = ['^node_modules$']

" FZF
" search git files
silent! noremap <C-p> :GFiles<CR>
" search inside files
nnoremap <leader>f :Rg!<CR>
" re-search when updating Rg query in preview
function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction
command! -nargs=* -bang Rg call RipgrepFzf(<q-args>, <bang>0)
" use ag_raw so can add arguments for specific file type, like
" ':Ag --vim ag_raw' // 'ag --list-file-types'
" ':Ag -G /*.file_suffix$ text'
command! -nargs=* -bang Ag call fzf#vim#ag_raw(<q-args>, <bang>0)

" Completion
let g:coc_global_extensions = [
  \ 'coc-tsserver',
  \ 'coc-eslint',
  \ 'coc-prettier',
  \ 'coc-omnisharp',
  \ 'coc-python',
  \ 'coc-clangd',
  \ ]
set shortmess+=c
set signcolumn=yes

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" In func incase I want to run YCM simultaneously
fun! GoCoc()
  :CocEnable
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

" Different language behaviours
fun! OpenedFileIsCpp()
  call GoCoc()
  compiler customclang
  setlocal shiftwidth=2
  setlocal tabstop=2
  setlocal softtabstop=2
endfun
autocmd FileType c,cpp :call OpenedFileIsCpp()

autocmd FileType cs :call OpenedFileIsCs()
fun! OpenedFileIsCs()
  call GoCoc()
  compiler dotnet
  setlocal shiftwidth=4
  setlocal tabstop=4
  setlocal softtabstop=4
endfun
autocmd FileType cs :call OpenedFileIsCs()

fun! OpenedFileIsJs()
  call GoCoc()
  noremap <buffer> <silent> <leader>i :CocCommand prettier.formatFile<CR>
  setlocal shiftwidth=2
  setlocal tabstop=2
  setlocal softtabstop=2
endfun
autocmd FileType javascript,javascriptreact :call OpenedFileIsJs()

fun! OpenedFileIsTS()
  call GoCoc()
  noremap <buffer> <silent> <leader>i :CocCommand prettier.formatFile<CR>
  setlocal shiftwidth=2
  setlocal tabstop=2
  setlocal softtabstop=2
endfun
autocmd FileType typescript,typescriptreact,typescript.tsx :call OpenedFileIsTS()

fun! OpenedFileIsPy()
  call GoCoc()
  setlocal shiftwidth=4
  setlocal tabstop=4
  setlocal softtabstop=4
endfun
autocmd FileType python :call OpenedFileIsPy()

" Save file when cursor doesn't move or focus lost
fun! SaveIfFileExists()
  if filereadable(expand('%:p')) && filewritable(expand('%:p')) == 1
    write
  endif
endfun
autocmd CursorHold,FocusLost * call SaveIfFileExists()

fun! COpen()
	let view = winsaveview() "save cursor position
	let currentWindow = winnr() "save window cursor is in
	copen
	execute currentWindow . "wincmd w"
	call winrestview(view)
endfun

" Compile
fun! Compile()
	silent write %
	silent make %
	if ! empty(getqflist())
		call COpen()
	else
		cclose
		echon "Successfully compiled!"
	endif
endfun

nnoremap <F9> :call Compile()<CR>

" Switch to a different buffer
nnoremap <leader>b :Buffers<CR>

" Quick way to open and load init.vim
nnoremap <leader>ev :edit $MYVIMRC<CR>
nnoremap <leader>sv :write<CR>:source $MYVIMRC<CR>

" nvimdiff / git mergetool
nnoremap <leader>s1 :diffget BA<CR>
nnoremap <leader>s2 :diffget LO<CR>
nnoremap <leader>s3 :diffget RE<CR>

" Convenient cursor movement
nnoremap <C-k> {
nnoremap <C-j> }
vnoremap <C-k> {
vnoremap <C-j> }
nnoremap <C-h> ^
nnoremap <C-l> $

" Since insert mode C-h is backspace, C-l should delete char infront
inoremap <C-l> <del>

" Surround word with " or < or (
nnoremap <leader>" viw<esc>a"<esc>hbi"<esc>lel
nnoremap <leader>' viw<esc>a'<esc>hbi'<esc>lel
nnoremap <leader>< viw<esc>a><esc>hbi<<esc>lel
nnoremap <leader>( viw<esc>a)<esc>hbi(<esc>lel
"Test: flkjal alfkjalf lajslkf

" Copy to end of line, to match behaviour of D and C
nnoremap Y y$

" Cut and paste to system clipboard
vnoremap <leader>y "+y
nnoremap <leader>p "+p
nnoremap <leader>P "+P

" New sp windows open right or bottom
set splitbelow
set splitright

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

" Switch off network history
let g:netrw_dirhistmax = 0

" Mappings for quickfix window
nnoremap <leader>h :call COpen()<CR>
nnoremap <leader>j :write<CR>:cnext<CR>
nnoremap <leader>k :cprevious<CR>
nnoremap <leader>l :cclose<CR>

" Better line wrap
set showbreak=…

" Highlight match while typing search term
set incsearch

" Highlight search words, ESC to switch off hl
set hlsearch
nnoremap <silent> <ESC> :nohl<CR><ESC>
nohl " No highlight after reloading $MYVIMRC

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

" nvim-qt
if exists('g:GuiLoaded')
  GuiPopupmenu 0
  GuiFont Monospace:h11
  call GuiWindowMaximized(1)
endif
set noerrorbells visualbell t_vb=
