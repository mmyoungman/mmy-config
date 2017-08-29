" Mark Youngman's Neovim Settings
" Last change:	27 Sep 2016

" For Pathogen plugin
execute pathogen#infect()

" set color scheme
colorscheme altdesert 
"set encoding=utf-8 

" Make backspace work in insert mode
set backspace=indent,eol,start

" Switch syntax highlighting on
syntax on

" no Ex mode - conflict with "map Q gq" below?
" nnoremap Q <nop>

" Switch off network history
let g:netrw_dirhistmax = 0

" Mappings
" Convenient cursor movement
"nnoremap <C-k> <C-u>
"nnoremap <C-j> <C-d>
nnoremap <C-k> {
nnoremap <C-j> }
nnoremap <C-h> ^
nnoremap <C-l> $

" Don't skip wrapped long lines
nnoremap k gk
nnoremap j gj

" Copy to end of line
noremap Y y$

" Forgotten what this is for - some weird paragraphing thing
"map Q gq

" macros
" @a adds curly brackets below and puts cursor inside them in insert mode
let @a = 'o{o}O i'

" Use space as leader key
let mapleader = " "
"let g:mapleader = " "

nnoremap <leader>w :update<cr>
nnoremap <leader>q :qall<cr>
nnoremap <leader>c :close<cr>

" Surround word with "/</(
nnoremap <leader>" viw<esc>a"<esc>hbi"<esc>lel
nnoremap <leader>< viw<esc>a><esc>hbi<<esc>lel
nnoremap <leader>( viw<esc>a)<esc>hbi(<esc>lel
"Test: flkjal alfkjalf lajslkf

" So "cin(" or "dil<" insert/delete inside next/last ()/<> 
onoremap in( :<c-u>normal! f(vi(<cr>
onoremap il( :<c-u>normal! F)vi(<cr>
onoremap in< :<c-u>normal! f<vi<<cr>
onoremap il< :<c-u>normal! F>vi<<cr>
" Same as above but delete surrounding ()/<>/ as well
onoremap an( :<c-u>normal! f(va(<cr>
onoremap al( :<c-u>normal! F)va(<cr>
onoremap an< :<c-u>normal! f<va<<cr>
onoremap al< :<c-u>normal! F>va<<cr>
"Test for above: print foo(jflakjf) <jflkjafl> lkjalfkj

" Add {}
inoremap <leader>{ <esc>o{<esc>o}<esc>O
"nnoremap <leader>{ o{<esc>o}<esc>O<esc>

" Quick way to open init.vim
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
" Quick way to load init.vim
nnoremap <leader>sv :source $MYVIMRC<cr>

" Auto refresh after editing .vimrc
"augroup reload_vimrc
"    autocmd!
"    autocmd BufWritePost $MYVIMRC source $MYVIMRC
"augroup END

" View open buffers
"map <leader>b :ls<cr>

" C&P to clipboard
nnoremap <leader>y "+y
nnoremap <leader>p "+p
" Because 'd' also copies:
nnoremap <leader>P "0p
"set clipboard+=unnamedplus

" Change EasyMotion plugin default binding
let g:EasyMotion_leader_key = '<Leader>t'

" NERDTree plugin binding
nnoremap <leader>n :NERDTreeToggle<cr>

" session make and restore
nnoremap <leader>m :mksession!<cr>
nnoremap <leader>. :source Session.vim<cr>

" Map local leader
"let maplocalleader = ","
"nnoremap <localleader>a = something

" CTags bindings
" Open in vertical split
nnoremap <A-]> :vsp <cr>:exec("tag ".expand("<cword>"))<cr>
" Search for tags file up to home dir
"set tags=./tags;$HOME

" Vim-clang plugin stuff
let g:clang_diagsopt = '' 

" Deoplete stuff, if I ever get it working...
"let g:deoplete#enable_at_startup = 1
"let g:deoplete#sources#clang#libclang_path = "/usr/lib/llvm-3.8/lib/libclang.so"
"let g:deoplete#sources#clang#clang_header = "/usr/lib/llvn-3.8/lib/clang"   
"let g:deoplete#sources#clang#clang_complete_database = ""
" Have to manually access autocomp
"let g:deoplete#disable_auto_complete 1
" Automatically close scratch split
"autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif
" Tab something or other 
"inoremap <silent><expr> <tab> pumvisible() ? "\<C-n>" : deoplete#mappings#manual_complete()
" Tab completion 
"inoremap <silent><expr> <tab> pumvisible() ? "\<C-n>" : "\<tab>"

" Try to avoid all hit-enter prompts - Doesn't work?
"set shortmess=atI

" Abbreviated stuff
"iunmap ssig
"iabbrev ssig -- <cr>Mark Milan<cr>mmyoungman@blah.com

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
nnoremap <F9> :call CompileProgram()<cr><cr>
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

" highlight search words, ctrl-l to switch off hl
set hlsearch
" so no highlight after reloading $MYVIMRC
nohl
nnoremap <ESC> :nohl<CR><ESC>

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
"set autoread

"C indentation options
set cindent
"set cinoptions=g1,h1,N-s
set cinoptions+=(0

" Show syntax highlighting groups for word under cursor
nnoremap <C-S-P> :call <SID>SynStack()<CR>
function! <SID>SynStack()
if !exists("*synstack")
return
endif
echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

" Tab stuff
set shiftwidth=4
set tabstop=4
set softtabstop=4
set expandtab
set smarttab

" Scroll 8 lines before the bottom
set scrolloff=8

" Don't wrap
"set nowrap
" Wrap better
"set linebreak
"set sidescrolloff=15

" Folding
"set foldmethod = indent
"set foldnestmax = 3
" No fold by default
"set nofoldenable

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

"set ruler
"set cursorline

" automatically save files
" set autowrite

" what is this for?
" vnoremap _g y:exe "grep /" . escape(@", '\\/') . "/ *.c *.h"<CR>
" autocmd FileType text setlocal textwidth=78

" useful if using the same buffer for multiple files? not so useful for sp and
" tabs?
" set hidden

" if gui running, remove gui menu and toolbar and scroll bars
if has('gui_running')
set guioptions-=m
set guioptions-=T
set guioptions-=r
set guioptions-=L
endif

" ****
" Windows GUI tweaks
" ****
if has("gui_win32")
set guifont =DejaVu_Sans_Mono:h9:cANSI
"autocmd GUIEnter * :simalt ~x
" set shellslash
endif

" THIS CAUSES A BUG IN NEOVIM? " maximise gvim window at startup
"set lines=99 columns=999

" make visualbell so it does nothing (accompanied by line in gvimrc to stop
" screen flashing on error)
set noerrorbells visualbell t_vb=

"set dir of ctags utility (not plugin folder)
"if has("win32")
"  let Tlist_Ctags_Cmd = "C:\Users\Mark\vimfiles\ctags.exe"
"endif
