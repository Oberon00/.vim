" Vim indent file
" Language:    Pascal
" Original Maintainer:  Neil Carter <n.carter@swansea.ac.uk>
" Created:     2004 Jul 13
" Last Change: 2014 Feb 28
"
" This is version 3.0, another complete rewrite.
"

if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

setlocal indentexpr=GetPascalIndent(v:lnum)
setlocal indentkeys&
setlocal indentkeys+=0=~end.,;,0=~const,0=~type,0=~var,0=~begin,0=~until
setlocal indentkeys+=0=~interface,0=~implementation,=~class,0=~unit
setlocal indentkeys+=0=~program,=~function,=~procedure,=~object
setlocal indentkeys+=0=~private,0=~protected,0=~public,0=~published
setlocal indentkeys+==~record,0=~else,0=~case
setlocal indentkeys+=0=~else,0=~do,0=~then,0=~of
if exists('pascal_delphi')
    setlocal indentkeys+=0=~except,0=~finally
endif

if exists("*GetPascalIndent")
    finish
endif

let s:maxParOff = 30  " Nb of lines to look back for unmatched '(' or '['.


function! s:IsComment(lnum, col)
    return synIDattr(synID(a:lnum, a:col, 0), 'name')
                \ =~? '\(Comment\|Todo\|PreProc\)$'
endfunction

function! s:IsNonCode(lnum, col)
    return synIDattr(synID(a:lnum, a:col, 0), 'name')
                \ =~? '\(Comment\|Todo\|PreProc\|String\)$'
endfunction

let s:commentStartPat = '{\|(\*'
let s:commentEndPat = '}\|\*)'
let s:nonCodeStartPat = "'" . '\|{\|(\*'
let s:nonCodeEndPat   = "'" . '\|}\|\*)'

function! s:LStripLine(lnum)
    let lstr = getline(a:lnum)
    let llen = strlen(lstr)

    let iStart = 0
    let i = iStart
    while 1
        " Skip whitespace
        let i = matchend(lstr, '^\s\+', i)
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
    return strpart(lstr, iStart)
endfunction


function! s:StrStripWs(s)
    return substitute(a:s, '^\s\+\|\s\+$', '', 'g')
endfunction

" Removes all comments, preprocessor comments and strings from the line.
" Returns the stripped string and a list of [strIdx, colOffset] pairs,
" sorted by strIdx, descending. This is for use with StrippedIdxToCol.
function! s:FullStripLine(lnum)
    let str = s:LStripLine(a:lnum)  " Comment could start on previous line

    " Add 1 to form a column index (instead of a string index)
    let iStart = strlen(getline(a:lnum)) - strlen(str) + 1
    echom 'str: "' . str . '"; iStart: ' . iStart
    let offsets = [[0, iStart]]
    let i = 1
    while 1

        " Find start of comment or string
        let i = match(str, s:nonCodeStartPat, i)
        echom 'match at ' . i
        if i < 0
            return [s:StrStripWs(str), offsets]
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
                return [s:StrStripWs(strpart(str, 0, i)), offsets]
            endif
            if !s:IsNonCode(a:lnum, iStart + j)
                break  " Found it!
            endif
            let j += 1
        endwhile
        let str = strpart(str, 0, i) . strpart(str, j)
        let iStart += j - i
        call insert(offsets, [i, iStart])
        echom 'str: "' . str . '"; iStart: ' . iStart . '; i: ' . i
    endwhile
endfunction

"function! PasFullStripLine(lnum)
"    return s:FullStripLine(a:lnum)
"endfunction

function! s:StrippedIdxToCol(idx, offs)
    for [begIdx, offset] in a:offs
        if begIdx <= a:idx
            return a:idx + offset
        endif
    endfor
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
                \ 's:IsNonCode(".", ".")', max([1, a:stopline]))
endfunction

let s:secStartPat = '\c^\(const\|var\|type\|uses'
if exists('pascal_delphi')
    let s:secStartPat .= '\|public\|protected\|private\|published'
endif
let s:secStartPat .= '\)\>'

let s:beginLikePat = '\c\<\(record\|begin\|of'
if exists('pascal_delphi')
    let s:beginLikePat .= '\|class\|object\|except\|finally'
endif
let s:beginLikePat .= '\)'

let s:chapStartPat =
            \ '\c^\(interface\|implementation\|\(program\|unit\)\>.\+;\)$'


" Return how many more open than close pars are on this line (negative: more
" closing ones)
function! s:ParDiff(lstr)
   let nOpen = strlen(substitute(a:lstr, '[^[(]', '', 'g'))
   let nClose = strlen(substitute(a:lstr, '[^\])]', '', 'g'))
   return nOpen - nClose
endfunction

function! s:FindPrevLineWith(pat, lnum, stopline)
    let lnum = a:lnum
    while lnum > a:stopline
        let lnum = s:GetPrevCodeLineNum(lnum)
        if lnum <= 0
            return [lnum, '']
        endif
        let [lstr, offs] = s:FullStripLine(lnum)
        if lstr =~? a:pat
            return [lnum, lstr]
        endif
    endwhile
    return 0
endfunction

function! s:IsStrIncompleteStmt(s)
    return a:s !~? s:beginLikePat . '$' && a:s !~? s:secStartPat
                \ && a:s !~? s:chapStartPat
                \ && a:s !~? '\<\(repeat\|do\|then\|else\|of\)$\|;$'
                \ && (!exists('pascal_delphi') || a:s !~? '\<try$')
endfunction

function! GetPascalIndent(lnum)
    let plnum = s:GetPrevCodeLineNum(a:lnum)

    if plnum <= 0  " (Before) first code line in the file
        echom a:lnum . ': #1: First line.'
        return 0
    endif

    let [lstr, loffs] = s:FullStripLine(a:lnum)
    "if lstr ==# '' &&  match(getline(a:lnum), '\S') >= 0
    "    echom a:lnum . ': #2: Comment or string.'
    "    return indent(plnum)
    "endif

    if lstr =~? s:chapStartPat
        echom a:lnum . ': #2+1: chapStart.'
        return 0
    endif

    let [plstr, ploffs] = s:FullStripLine(plnum)
    let dedent = min([indent(a:lnum), max([0, indent(plnum) - &shiftwidth])])

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
            let parDiff += s:ParDiff(s:FullStripLine(mlnum)[0])
        endwhile
        if mlnum > 0
            if parDiff > 0
                echom a:lnum . ': #2+2: pars do not close all on opening line'
                return indent(mlnum) + &shiftwidth
            endif
            echom a:lnum . ': #3+2: closing pars on this or prev line' . mlnum
            return indent(mlnum)
        endif
    endif


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

    if plstr =~? s:chapStartPat
        if lstr =~? '^begin\>'
            " NOTE: This ignores that after "interface" (and "unit"?) "begin"
            " would be a syntax error.
            echom a:lnum . ': #3+3: begin after chapStart'
            return indent(plnum)
        endif
        echom a:lnum . ': #4+1: First line after chapStart'
        return indent(plnum) + &shiftwidth
    endif

    if lstr =~? '^end\>'
        call cursor(a:lnum, 1)
        let mlnum = searchpair(s:beginLikePat . '\>', '', '\c\<end\>',
                    \ 'bW', 's:IsNonCode(".", ".")')
        if mlnum > 0
            echom a:lnum . ': #5: end ind. to matching beg-like @' . mlnum
            return indent(mlnum)
        endif
        echom a:lnum . ': #5+1: end w/o matching begin-like'
        return 0
    endif

    if lstr =~? '^until\>'
        call cursor(a:lnum, 1)
        let mlnum = searchpair('\c\<repeat\>', '', '\c\<until\>',
                    \ 'bW', 's:IsNonCode(".", ".")')
        if mlnum > 0
            echom a:lnum . ': #6: until indented to matching repeat @' . mlnum
            return indent(mlnum)
        endif
        echom a:lnum . ': #6+1: until w/o matching repeat'
        return 0
    endif

    if exists('pascal_delphi') && lstr =~? '^\(except\|finally\)\>'
        call cursor(a:lnum, 1)
        let mlnum = searchpair('\c\<try\>', '', '\c\<\(except\|finally\)\>',
                    \ 'bW', 's:IsNonCode(".", ".")')
        if mlnum > 0
            echom a:lnum . ': #6: exc/fin indented to matching try @' . mlnum
            return indent(mlnum)
        endif
        echom a:lnum . ': #6+1: except/finally w/o matching try'
        return 0
    endif

    if plstr =~? s:beginLikePat . '$' || plstr =~? '\<repeat$'
                \ || exists('pascal_delphi') && plstr =~? '\<try$'
        echom a:lnum . ': #12+1: line following begin-like'
        return indent(plnum) + &shiftwidth
    endif

    let pSecStart = matchend(plstr, s:secStartPat . '\s*')
    let lIsSecStart = lstr =~? s:secStartPat
    if pSecStart >= 0
        call cursor(plnum, s:StrippedIdxToCol(pSecStart, ploffs))
        let parLNum = s:SearchParPair(plnum - s:maxParOff)
        " "var" and "const" may appear as function argument modifiers
        if parLNum <= 0 || getline(".")[col(".") - 1] !~? '(\|\['
            if !lIsSecStart && lstr !~? '^\(begin\|function\|procedure\)\>'
                if pSecStart == strlen(plstr)
                    echom a:lnum . ': #9: Section start at EOL'
                    return indent(plnum) + &shiftwidth
                endif
                echom a:lnum . ': #10: Section start with trailing code'
                " Indent is one less than the position
                return s:StrippedIdxToCol(pSecStart, ploffs) - 1
            endif
            if lstr =~? '^begin\>'
                echom a:lnum . ': #10+1: begin after section start'
                return dedent;
            endif
            echom a:lnum . ': #11: Consecutive section starts'
            return indent(plnum)
        endif
    endif

    if lIsSecStart
        " Align with previous secStart, if any
        let [pSecStartLNum, pSecStartLStr] = s:FindPrevLineWith(
                    \ s:secStartPat . '\|^\(function\|procedure\)\>',
                    \ plnum + 1, plnum - s:maxParOff)
        if pSecStartLStr =~? '^\(function\|procedure\)\>'
            echom a:lnum . ': #12+1: Section start following func/proc'
            return -1
        endif
        call cursor(pSecStartLNum, 1)
        if s:SearchParPair(pSecStartLNum - s:maxParOff) > 0
            echom a:lnum . ': #12+2: Section start following prob. func/proc'
            return -1
        endif
        echom a:lnum . ': #12+3: Section start (aligned with previous one)'
        return indent(pSecStartLNum)
    endif

    if plstr =~? '\<\(do\|then\|else\)$'
        if lstr =~? '^begin\>' 
            echom a:lnum . ': #12: begin following do, then or else'
            return indent(plnum)
        endif
        echom a:lnum . ': #12+0+1: Line != begin following do, then or else'
        return indent(plnum) + &shiftwidth
    endif

    
    if plstr !~? ';$'
        if lstr =~? '\<\(do\|then\|else\|of\)$'
            echom a:lnum . ': #13: else/do/of/then after line w/o trailing ;'
            return dedent
        endif
        let pplnum = s:GetPrevCodeLineNum(plnum)
        if pplnum > 0
            let [pplstr, pploffs] = s:FullStripLine(pplnum)
            if !s:IsStrIncompleteStmt(pplstr)
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
        let [pplstr, pploffs] = s:FullStripLine(pplnum)
        if s:IsStrIncompleteStmt(pplstr)
            echom a:lnum . ': #16+1: Next statement after continuation.'
            return dedent
        endif
    endif

    echom a:lnum . ': #0: No rule found'
    return -1
endfunction

