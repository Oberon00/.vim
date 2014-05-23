" File: pashgb.vim
" Author: Christian Neumüller
" Description: Common functions for the pascal plugin
" Last Modified: Mai 03, 2014

function! pashgb#IsNonCode(lnum, col)
    return synIDattr(synID(a:lnum, a:col, 0), 'name')
                \ =~? '\%(Comment\|Todo\|PreProc\|String\)'
endfunction

let g:pashgb#isCursorNonCodeExpr = 'pashgb#IsNonCode(line("."), col("."))'

let s:beginLikePat = '\v\c<%(record|begin|case'
if exists('pascal_delphi')
    let s:beginLikePat .= '|class|object|except|finally'
endif
let s:beginLikePat .= ')>'

function! pashgb#SearchBegEndPair(flags)
    return searchpair(s:beginLikePat, '', '\v\c<end>',
                \ a:flags, g:pashgb#isCursorNonCodeExpr)
endfunction
