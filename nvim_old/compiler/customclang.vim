" To build clang program from build.sh

if exists("current_compiler")
  finish
endif
let current_compiler = "customclang"
let s:cpo_save = &cpo
set cpo&vim

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet errorformat=
      \%f:%l:%c:\ %trror:\ %m,
      \%f:%l:%c:\ %tarning:\ %m,
      \%f:%l:%c:\ %m,
CompilerSet makeprg=./scripts/build.sh

let &cpo = s:cpo_save
unlet s:cpo_save
