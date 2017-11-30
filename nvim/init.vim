" Mark Youngman's Neovim Settings
" Last change:	30 Nov 2017

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
" au VimEnter * vsplit

" Compile and Quickfix Stuff
nnoremap <F11> :call CompileProgram()<cr><cr>
nnoremap <F12> :!./run.sh<cr>

" mappings for quickfix window
nnoremap <leader>j :cnext<cr>
nnoremap <leader>k :cprevious<cr>
nnoremap <leader>l :call QuickfixToggle()<cr>

" To complile a c++ program and put any errors in quickfix
let g:quickfix_is_open = 0

function! CompileProgram()
    if has("unix")
        "silent !g++ -ggdb % -lX11 2>quickfixerrorfile
        silent !./build.sh 2>quickfixerrorfile
        silent cfile quickfixerrorfile
        if !empty(readfile("quickfixerrorfile"))
            let g:quickfix_return_to_window = winnr()
            copen
            execute g:quickfix_return_to_window . "wincmd w"
            let g:quickfix_is_open = 1
            else
            silent !rm quickfixerrorfile
            echo "No errors found."
            cclose
            let g:quickfix_is_open = 0
        endif
    elseif has("win32")
        " silent !cl /nologo /EHsc % >quickfixerrorfile
        silent !build.bat >quickfixerrorfile
        silent cfile quickfixerrorfile
        if (match(readfile("quickfixerrorfile"), "error") + 1) || (match(readfile("quickfixerrorfile"), "warning") + 1)
            let g:quickfix_return_to_window = winnr()
            copen
            execute g:quickfix_return_to_window . "wincmd w"
            let g:quickfix_is_open = 1
        else
            silent !del quickfixerrorfile
            echo "No errors found."
            cclose
            let g:quickfix_is_open = 0
        endif
    endif
endfunction

function! QuickfixToggle()
    if g:quickfix_is_open
        cclose
        let g:quickfix_is_open = 0
        execute g:quickfix_return_to_window . "wincmd w"
    else
        let g:quickfix_return_to_window = winnr()
        copen
        "vert copen 80 " vsp quickfix
        execute g:quickfix_return_to_window . "wincmd w"
        " quickfix buffer opens on bottom first time, then left afterwards
        " autocmd FileType qf wincmd L
        let g:quickfix_is_open = 1
    endif
endfunction

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
set shiftwidth=4
set tabstop=4
set softtabstop=4
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
