" Vim compiler file
" Compiler:     FPC 2.6
" Last Change:  2014 February 26

if exists("current_compiler")
  finish
endif

let current_compiler = "fpcD"

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=fpc\ -Criot\ -vewhnb\ -gclt\ %
CompilerSet errorformat=%f(%l\\,%c)\ %m
