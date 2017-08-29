" Mark Youngman's AltDesert.vim, based on Desert.vim
" Last change: 2016 Sep 1
"
" Original Desert.vim:
" Maintainer:	Hans Fugal <hans@fugal.net>
" Last Change:	$Date: 2004/06/13 19:30:30 $
" Last Change:	$Date: 2004/06/13 19:30:30 $
" URL:		http://hans.fugal.net/vim/colors/desert.vim
" Version:	$Id: desert.vim,v 1.1 2004/06/13 19:30:30 vimboss Exp $
" cool help screens
" :he group-name
" :he highlight-groups
" :he cterm-colors

set background=dark
if version > 580
    " no guarantees for version 5.8 and below, but this makes it stop
    " complaining
    hi clear
    if exists("syntax_on")
	syntax reset
    endif
endif
let g:colors_name="altdesert"

hi Normal	guifg=White guibg=grey20

" highlight groups
hi Cursor	guibg=khaki guifg=grey
"hi CursorIM
"hi Directory
"hi DiffAdd
"hi DiffChange
"hi DiffDelete
"hi DiffText
"hi ErrorMsg
hi VertSplit	guibg=#c2bfa5 guifg=grey50 gui=none
hi Folded	guibg=grey30 guifg=gold
hi FoldColumn	guibg=grey30 guifg=tan
hi IncSearch	guifg=grey guibg=khaki
"hi LineNr
hi ModeMsg	guifg=goldenrod
hi MoreMsg	guifg=SeaGreen
hi NonText	guifg=LightBlue guibg=grey30
hi Question	guifg=springgreen
hi Search	guibg=peru guifg=wheat
hi SpecialKey	guifg=yellowgreen
hi StatusLine	guibg=#c2bfa5 guifg=black gui=none
hi StatusLineNC	guibg=#c2bfa5 guifg=grey50 gui=none
hi Title	guifg=indianred
hi Visual	gui=none guifg=khaki guibg=olivedrab
"hi VisualNOS
hi WarningMsg	guifg=salmon
"hi WildMenu
"hi Menu
"hi Scrollbar
"hi Tooltip

" syntax highlighting groups
hi Comment	guifg=SkyBlue
hi Constant	guifg=#ffa0a0
hi Identifier	guifg=palegreen
hi Statement	guifg=khaki
hi PreProc	guifg=indianred
hi Type		guifg=darkkhaki
hi Special	guifg=navajowhite
"hi Underlined
hi Ignore	guifg=grey40
"hi Error

" NOTE(mark): I'm currently using "match" to highlight TODO NOTE and IMPORTANT. 
" It doesn't work. And this could make vim slow if I use it to highlight lots 
" of keywords. It will (apparently) be faster using "syntax keyword MyGroup
" word", but it seems to do that I need to create a custom syntax file, like
" .vim/after/syntax/c.vim. It seems I cannot just add it to this file.
" http://stackoverflow.com/questions/4162664/vim-highlight-a-list-of-words
" https://www.reddit.com/r/vim/comments/15zmpi/how_can_you_set_syntax_highlighting_for_specific/
"
" altdesert changes to TODO: 
hi Todo ctermfg=red ctermbg=NONE cterm=bold,underline guifg=orangered guibg=NONE gui=bold,underline
"hi cTodo ctermfg=red ctermbg=NONE cterm=bold,underline guifg=orangered guibg=NONE gui=bold,underline
"hi AltDesertTodo ctermfg=red ctermbg=NONE cterm=bold,underline guifg=orangered guibg=NONE gui=bold,underline
match Todo /TODO/
"syntax keyword Todo TODO

" altdesert changes to NOTE:
hi AltDesertNote ctermfg=green ctermbg=NONE cterm=bold,underline guifg=green guibg=NONE gui=bold,underline
2match AltDesertNote /NOTE/
"syntax keyword AltDesertNote NOTE

" altdesert changes to IMPORTANT:
hi AltDesertImportant ctermfg=yellow ctermbg=NONE cterm=bold,underline guifg=yellow guibg=NONE gui=bold,underline
"3match AltDesertImportant /IMPORTANT/
"syntax keyword AltDesertImportant IMPORTANT

" color terminal definitions
hi SpecialKey	ctermfg=darkgreen
hi NonText	cterm=bold ctermfg=darkblue
hi Directory	ctermfg=darkcyan
hi ErrorMsg	cterm=bold ctermfg=7 ctermbg=1
hi IncSearch	cterm=NONE ctermfg=red ctermbg=black
hi Search	cterm=NONE ctermfg=black ctermbg=red "ctermbg=blue
hi MoreMsg	ctermfg=darkgreen
hi ModeMsg	cterm=NONE ctermfg=brown
hi LineNr	ctermfg=3
hi Question	ctermfg=green
hi StatusLine	cterm=bold,reverse
hi StatusLineNC cterm=reverse
hi VertSplit	cterm=reverse
hi Title	ctermfg=5
hi Visual	cterm=reverse
hi VisualNOS	cterm=bold,underline
hi WarningMsg	ctermfg=1
hi WildMenu	ctermfg=0 ctermbg=3
hi Folded	ctermfg=darkgrey ctermbg=NONE
hi FoldColumn	ctermfg=darkgrey ctermbg=NONE
hi DiffAdd	ctermbg=4
hi DiffChange	ctermbg=5
hi DiffDelete	cterm=bold ctermfg=4 ctermbg=6
hi DiffText	cterm=bold ctermbg=1
hi Comment	ctermfg=darkcyan
hi Constant	ctermfg=brown
hi Special	ctermfg=5
hi Identifier	ctermfg=6
hi Statement	ctermfg=3
hi PreProc	ctermfg=5
hi Type		ctermfg=2
hi Underlined	cterm=underline ctermfg=5
hi Ignore	cterm=bold ctermfg=7
hi Ignore	ctermfg=darkgrey
hi Error	cterm=bold ctermfg=7 ctermbg=1

"vim: sw=4
