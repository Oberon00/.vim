" File: colorutil.vim
" Author: Christian Neumüller
" Description: Some utils for colorschemes.

function colorutil#LinkStartify()
    hi! link StartifyNumber Number
    hi! link StartifySection Title
    hi! link StartifyFile Identifier
    hi! link StartifySpecial Type
endfunction

function colorutil#LinkKWOperatorsToKWs()
    hi! link pascalOperator Keyword
    hi! link luaOperator Keyword
endfunction

function colorutil#LinkKWOperatorsToOperators()
    hi! link pascalOperator Operator
    hi! link luaOperator Operator
endfunction
