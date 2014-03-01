" Vim indent file
" Language:    Pascal
" Original Maintainer:  Neil Carter <n.carter@swansea.ac.uk>
" Created:     2004 Jul 13
" Last Change: 2014 Feb 28
"
" This is version 3.0, a complete rewrite.
"

if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

setlocal indentexpr=GetPascalIndent(v:lnum)
setlocal indentkeys&
setlocal indentkeys+=;,0=~const,0=~type,0=~var,0=~begin,0=~until
setlocal indentkeys+=0=~interface,0=~implementation,=~class,0=~unit
setlocal indentkeys+=0=~program,=~function,=~procedure,=~object
setlocal indentkeys+=0=~private,0=~protected,0=~public,0=~published
setlocal indentkeys+==~record,0=~if,0=~else,0=~case
setlocal indentkeys+=0=~else,0=~do,0=~then,0=~of

if exists("*GetPascalIndent")
    finish
endif

set debug+=msg
let s:maxParOff = 30  " Nb of lines to look back for unmatched '(' or '['.


function! s:IsComment(lnum, col)
    return synIDattr(synID(a:lnum, a:col, 0), 'name')
                \ =~? '\(Comment\|Todo|PreProc\)$'
endfunction

function! s:IsNonCode(lnum, col)
    return synIDattr(synID(a:lnum, a:col, 0), 'name')
                \ =~? '\(Comment\|Todo|PreProc\|String\)$'
endfunction

let s:nonCodeStartPat = "'" . '\|{\|(\*'
let s:nonCodeEndPat   = "'" . '\|}\|\*)'

function! s:LStripLine(lnum)
    let lstr = getline(a:lnum)
    let llen = len(lstr)

    let iStart = 0
    let i = iStart
    while 1
        " Skip whitespace
        let i = matchend(lstr, '^\s\+', i + 1)
        let i = i < 0 ? iStart : i

        " Skip comment and string
        while i < llen && s:IsNonCode(a:lnum, i + 1)
            let r = matchend(lstr, s:nonCodeEndPat, i)
            if r < 0
                return ''
            endif
            let i = r
        endwhile
        if i == iStart " Stop if no progress has been made
            break
        endif
        let iStart = i
    endwhile

    if iStart > 0 && lstr[iStart - 1] == "'"
        let prefix = "''"
    else
        let prefix = ""
    endif
    return prefix . strpart(lstr, iStart)
endfunction


function! s:StrRStripWs(s)
    return strpart(a:s, 0, match(a:s, '\s*$'))
endfunction

function! s:FullStripLine(lnum)
    let str = s:LStripLine(a:lnum)  " Comment could start on previous line

    " Add 1 to form a column index (instead of a string index)searchpair('(\|\[', '', ')\|\]', 'bW',
    let iStart = strlen(getline(a:lnum)) - strlen(str) + 1
    let i = 1
    while 1

        " Find start of comment or string
        let i = match(str, s:nonCodeStartPat, i)
        if i < 0
            return s:StrRStripWs(str)
        endif
        if !s:IsNonCode(a:lnum, iStart + i)
            let i += 1
            continue
        endif

        " Find end of this comment or string
        let j = i + 1
        while 1
            let j = matchend(str, s:nonCodeEndPat, j)
            if j < 0 " No more code on this line
                return s:StrRStripWs(strpart(str, 0, i))
            endif
            if !s:IsNonCode(a:lnum, iStart + j)
                break  " Found it!
            endif
            let j += 1
        endwhile

        let iStart += j
        let mid = str[i] == "'" ? "''" : ""
        let str = strpart(str, 0, i) . mid . strpart(str, j)
        let i = 0
    endwhile
endfunction

function! PasFullStripLine(lnum)
    return s:FullStripLine(a:lnum)
endfunction


function! s:GetPrevCodeLineNum(lnum)

    " Skip lines consisting only of comments and/or whitespace
    let nline = a:lnum
    while nline > 0
        let nline = prevnonblank(nline - 1)
        if s:LStripLine(nline) !=# ''
            break
        endif
    endwhile
    return nline
endfunction

function! s:SearchParPair(stopline)
    return searchpair('(\|\[', '', ')\|\]', 'bW',
                \ 's:IsNonCode(".", ".")', max([0, a:stopline]))
endfunction

let s:secStartPat = '\c^\(const\|var\|type\|uses\|'
            \ . 'public\|protected\|private\|published\)\>'
let s:beginLikePat = '\c\<\(record\|class\|object\|'
            \. 'begin\|case\>.\+\<of\|repeat\)$'
let s:chapStartPat = '\c^\(interface\|implementation\|\(program\|unit\)\>.\+;\)$'


" Return how many more open than close pars are on this line (negative: more
" closing ones)
function! s:ParDiff(lstr)
   let nOpen = strlen(substitute(a:lstr, '[^[(]', '', 'g'))
   let nClose = strlen(substitute(a:lstr, '[^\])]', '', 'g'))
   return nOpen - nClose
endfunction

function! GetPascalIndent(lnum)
    let plnum = s:GetPrevCodeLineNum(a:lnum)

    if plnum <= 0  " (Before) first code line in the file
        echom a:lnum . ': #1: First line.'
        return 0
    endif

    let lstr = s:FullStripLine(a:lnum)
    "if lstr ==# '' &&  match(getline(a:lnum), '\S') >= 0
    "    echom a:lnum . ': #2: Comment or string.'
    "    return indent(plnum)
    "endif

    if lstr =~? s:chapStartPat
        echom a:lnum . ': #2+1: chapStart.'
        return 0
    endif

    let plstr = s:FullStripLine(plnum)
    let dedent = max([0, indent(plnum) - &shiftwidth])

    call cursor(plnum + 1, 1)
    if s:SearchParPair(plnum) > 0
        echom 'Found unmatched par on previous line'
        if getline('.')[col('.') - 1] =~? '\[\|('  " more opening pars?
            let parIdx = max([strridx(plstr, '('), stridx(plstr, '[')])
            if parIdx == strlen(plstr) - 1
                echom a:lnum . ': #3: Unmatched [ or ( in previous line @EOL'
                return indent(plnum) + &shiftwidth
            endif
            echom a:lnum . ': #3+1 Unmatched [ or ( in previous line, not @EOL'
            return col('.') 
        endif
    endif

    if lstr =~? '^[)\]]\+'
        let parDiff = s:ParDiff(lstr)
        let mlnum = a:lnum
    else
        let parDiff = s:ParDiff(plstr)
        let mlnum = plnum
    endif
    if parDiff < 0
        while parDiff < 0 && mlnum > 0
            echom 'parDiff at ' . mlnum . ': ' . parDiff
            let mlnum = s:GetPrevCodeLineNum(mlnum)
            let parDiff += s:ParDiff(s:FullStripLine(mlnum)) 
        endwhile
        if mlnum > 0
            echom a:lnum . ': #3+2: closing pars on this or prev line' . mlnum
            return indent(mlnum)
        endif
    endif

    if plstr =~? s:chapStartPat
        if lstr =~? '^begin\>' && plstr
            " NOTE: This ignores that after "interface" (and "unit"?) "begin"
            " would be a syntax error.
            echom a:lnum . ': #3+3: begin after chapStart'
            return indent(plnum)
        endif
        echom a:lnum . ': #4+1: First line after chapStart'
        return indent(plnum) + &shiftwidth
    endif

    if lstr =~? '^end\>'
        if plstr =~? s:beginLikePat
            echom a:lnum . ': #5: end w/ preceding begin-like'
            return indent(plnum)
        endif
        echom a:lnum . ': #6: end w/o preceding begin-like'
        return dedent 
    endif  " if lstr =~? '^end\>'

    if lstr =~? '^until\>'
        if plstr =~? '^repeat\>'
            echom a:lnum . ': #7: until w/ preceding repeat'
            return indent(plnum)
        endif
        echom a:lnum . ': #8: until w/o precding repeat'
        return dedent
    endif " if lstr =~? '^until\>'

    if plstr =~? s:beginLikePat
        echom a:lnum . ': #12+1: line following begin-like'
        return indent(plnum) + &shiftwidth
    endif

    let secstart = matchend(plstr, s:secStartPat . '\s*')
    call cursor(plnum, secstart)
    let parLNum = s:SearchParPair(plnum - s:maxParOff)
    " "var" and "const" may appear as function argument modifiers
    if parLNum <= 0 || getline(".")[col(".") - 1] !~? '(\|\['
        if secstart >= 0
            if lstr !~? s:secStartPat && lstr !~? '^begin\>'
                if secstart == strlen(plstr)
                    echom a:lnum . ': #9: Section start at EOL'
                    return indent(plnum) + &shiftwidth
                endif
                echom a:lnum . ': #10: Section start with trailing code'
                return indent(plnum) + secstart
            endif
            echom a:lnum . ': #11: Consecutive section starts'
            return indent(plnum)
        endif
    endif

    if plstr =~? '\<\(do\|then\|else\)$'
        if lstr =~? '^begin\>' 
            echom a:lnum . ': #12: begin following do, then or else'
            return indent(plnum)
        endif
        echom a:lnum . ': #12+0+1: Line != begin following do, then or else'
        return indent(plnum) + &shiftwidth
    endif

    let pIsFuncStart =
                \ plstr =~? '\<\(function\|procedure\)\>'
                \ && plstr !~? '\<forward\s*;'
    if lstr =~? '^begin\>' && pIsFuncStart
        echom a:lnum . ': #12+2: Function code starts here'
        return indent(plnum)
    endif

    if plstr !~? ';$'
        if lstr =~? '\<\(do\|then\|else\|of\)$'
            echom a:lnum . ': #13: else/do/of/then after line w/o trailing ;'
            return dedent
        endif
        let pplnum = s:GetPrevCodeLineNum(plnum)
        if pplnum > 0
            let pplstr = s:FullStripLine(pplnum)
            if pplstr =~? s:beginLikePat || pplstr =~? s:secStartPat
                        \ || pplstr =~? s:chapStartPat
                        \ || pplstr =~? '\<\(do\|then\|else\|of\)$'
                echom a:lnum . ': #14: first line following one w/o ;'
                return indent(plnum) + &shiftwidth
            endif
            echom a:lnum . ': #15: line following more than one w/o ;'
            return indent(plnum)
        endif
        echom a:lnum . ': #16: line following one w/o ; which is the first'
        return indent(plnum) + &shiftwidth
    endif  " if plstr !~= ';$'

    if plstr =~? '\<\(function\|procedure\)\>.*;.*\<forward\>' 
        echom a:lnum . ': #17: line following proc/func forward declaration.'
        return indent(plnum)
    endif

    let pplnum = s:GetPrevCodeLineNum(plnum)
    if pplnum > 0
        let pplstr = s:FullStripLine(pplnum)
        if pplstr =~? '\<\(do\|then\|else\)$'
            echom a:lnum . ': #16+1: Single-sub-stmt controlstatement ended.'
            return dedent
        endif
    endif

    echom a:lnum . ': #0: No rule found'
    return -1
endfunction

