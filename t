[1mdiff --git a/nvim/init.vim b/nvim/init.vim[m
[1mindex a7f1445..5c15dfe 100644[m
[1m--- a/nvim/init.vim[m
[1m+++ b/nvim/init.vim[m
[36m@@ -1,7 +1,5 @@[m
 " Mark Youngman's Neovim Settings[m
 [m
[31m-" pip install neovim[m
[31m-" npm install -g neovim[m
 call plug#begin('~/.config/nvim/plugged')[m
 [m
 Plug 'neoclide/coc.nvim', {'branch': 'release'}[m
[36m@@ -32,7 +30,23 @@[m [mautocmd BufEnter * call NERDTreeSync()[m
 let g:NERDTreeIgnore = ['^node_modules$'][m
 [m
 " FZF[m
[32m+[m[32m" search git files[m
 silent! noremap <C-p> :GFiles<CR>[m
[32m+[m[32m" search inside files[m
[32m+[m[32mnnoremap <leader>f :Rg!<CR>[m
[32m+[m[32m" re-search when updating Rg query in preview[m
[32m+[m[32mfunction! RipgrepFzf(query, fullscreen)[m
[32m+[m[32m  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'[m
[32m+[m[32m  let initial_command = printf(command_fmt, shellescape(a:query))[m
[32m+[m[32m  let reload_command = printf(command_fmt, '{q}')[m
[32m+[m[32m  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}[m
[32m+[m[32m  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)[m
[32m+[m[32mendfunction[m
[32m+[m[32mcommand! -nargs=* -bang Rg call RipgrepFzf(<q-args>, <bang>0)[m
[32m+[m[32m" use ag_raw so can add arguments for specific file type, like[m[41m [m
[32m+[m[32m" ':Ag --vim ag_raw' // 'ag --list-file-types'[m
[32m+[m[32m" ':Ag -G /*.file_suffix$ text'[m
[32m+[m[32mcommand! -nargs=* -bang Ag call fzf#vim#ag_raw(<q-args>)[m
 [m
 " Completion[m
 let g:coc_global_extensions = [[m
[36m@@ -117,7 +131,7 @@[m [mautocmd FileType python :call OpenedFileIsPy()[m
 [m
 " Save file when cursor doesn't move or focus lost[m
 fun! SaveIfFileExists()[m
[31m-  if filereadable(expand('%:p')) && filewritable(expand('%:p'))[m
[32m+[m[32m  if filereadable(expand('%:p')) && filewritable(expand('%:p')) == 1[m
     write[m
   endif[m
 endfun[m
[36m@@ -126,9 +140,6 @@[m [mautocmd CursorHold,FocusLost * call SaveIfFileExists()[m
 " Switch to a different buffer[m
 nnoremap <leader>b :Buffers<CR>[m
 [m
[31m-" Search inside files[m
[31m-nnoremap <leader>f :Rg!<space>[m
[31m-[m
 " Quick way to open and load init.vim[m
 nnoremap <leader>ev :edit $MYVIMRC<CR>[m
 nnoremap <leader>sv :source $MYVIMRC<CR>[m
