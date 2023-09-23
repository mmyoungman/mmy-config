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

" Switch to a different buffer
nnoremap <leader>b :Buffers<CR>

" Quick way to open and load init.vim
nnoremap <leader>ev :edit $MYVIMRC<CR>
nnoremap <leader>sv :write<CR>:source $MYVIMRC<CR>


" Switch off network history
let g:netrw_dirhistmax = 0

" C indentation options
"set cindent
"set cinoptions=g1,h1,N-s
"set cinoptions+=(0

" Scroll 8 lines before the bottom
set scrolloff=5