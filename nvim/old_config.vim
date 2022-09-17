" Mark Youngman's Neovim Settings

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
	let quickfix_is_open = winsaveview() "save cursor position
	let currentWindow = winnr() "save window cursor is in
	copen
	execute currentWindow . "wincmd w"
	call winrestview(quickfix_is_open)
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

fun! Analyse()
	silent write %
	silent !./scripts/analyse.sh 2> .analysis-results
	silent cfile .analysis-results
	silent !rm .analysis-results
	if ! empty(getqflist())
		call COpen()
	else
		cclose
		echon "Analyser didn't find any issues!"
	endif
endfun

fun! Format()
        let preformat_winview = winsaveview()
        let preformat_cursor_pos = getpos('.')
        :ClangFormat file
        call winrestview(preformat_winview)
        call setpos('.', preformat_cursor_pos)
endfun

nnoremap <F9> :call Compile()<CR>
nnoremap <F10> :call Format()<CR>
nnoremap <F11> :call Analyse()<CR>
nnoremap <F12> :!./scripts/run.sh<CR>

" nvimdiff / git mergetool
nnoremap <leader>s1 :diffget BA<CR>
nnoremap <leader>s2 :diffget LO<CR>
nnoremap <leader>s3 :diffget RE<CR>

" No auto insert comments on new line
autocmd FileType * set formatoptions-=cro

" Switch off network history
let g:netrw_dirhistmax = 0

" Mappings for quickfix window
nnoremap <leader>h :call COpen()<CR>
nnoremap <leader>j :write<CR>:cnext<CR>
nnoremap <leader>k :cprevious<CR>
nnoremap <leader>l :cclose<CR>

" nvim-qt
if exists('g:GuiLoaded')
  GuiPopupmenu 0
  GuiFont Monospace:h11
  call GuiWindowMaximized(1)
endif
set noerrorbells visualbell t_vb=
