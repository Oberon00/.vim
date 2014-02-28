" Vim indent file
" Language:    Pascal
" Maintainer:  Neil Carter <n.carter@swansea.ac.uk>
" Created:     2004 Jul 13
" Last Change: 2011 Apr 01
"
" This is version 2.0, a complete rewrite.
"
" For further documentation, see http://psy.swansea.ac.uk/staff/carter/vim/

set debug+=msg

if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

setlocal indentexpr=GetPascalIndent(v:lnum)
setlocal indentkeys&
setlocal indentkeys+==~end;,=~const,=~type,=~var,=~begin,=~repeat,=~until,=~for
setlocal indentkeys+==~interface,=~implementation,=~class,=~unit
setlocal indentkeys+==~program,=~function,=~procedure,=~object,=~private
setlocal indentkeys+==~record,=~if,=~else,=~case

if exists("*GetPascalIndent")
    finish
endif


function! s:IsComment(lnum, col)
    return synIDattr(synID(a:lnum, a:col, 0), 'name')
                \ =~? '\(Comment\|Todo|PreProc\)$'
endfunction

function! s:LStripLine(lnum)
    let lstr = getline(a:lnum)
    let llen = len(lstr)
    
    let iStart = 0
    let i = iStart
    while 1
        " Skip whitespace
        let i = matchend(lstr, '^\s\+', i + 1)
        let i = i < 0 ? iStart : i
        
        " Skip comment
        while i < llen && s:IsComment(a:lnum, i + 1)
           let r = matchend(lstr, '}\|\*)', i)
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


function! s:StrRStripWs(s)
    return strpart(a:s, 0, match(a:s, '\s*$'))
endfunction

function! s:FullStripLine(lnum)
    let str = s:LStripLine(a:lnum)

    " Add 1 to form a column index (instead of a string index)
    let iStart = strlen(getline(a:lnum)) - strlen(str) + 1
    let i = 0
    while 1

        " Find start of comment
        let i = match(str, '{\|(\*', i)
        if i < 0
            return s:StrRStripWs(str)
        endif
        if !s:IsComment(a:lnum, iStart + i)
            let i += 1
            continue
        endif
        
        " Find end of this comment
        let j = i
        while 1
            let j = matchend(str, '}\|\*)', j)
            if j < 0 || j == strlen(str) " No more code on this line
                return s:StrRStripWs(strpart(str, 0, i))
            endif
            if !IsComment(a:lnum, iStart + j)
                break " Found it!
            endif
            let j += 1
        endwhile

        let iStart += j
        let str = strpart(str, 0, i) . strpart(str, j)
        let i = 0
    endwhile
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


function! GetPascalIndent( lnum )

    " Line 0 always goes at column 1
    if a:lnum == 0
        return 0
    endif

    " SAME INDENT

    " Comment
     if s:IsComment(a:lnum, 1)
         return -1
     endif

    let this_codeline = s:FullStripLine( a:lnum )

    " COLUMN 1 ALWAYS

    " Last line of the program
    if this_codeline =~? '^end\.'
        return 0
    endif

    " section headers
    if this_codeline =~? '^program\>'
        return 0
    endif

    " Subroutine separators, lines ending with "const" or "var"
    if this_codeline =~? '^\((\*\ _\+\ \*)\|\(const\|var\)\)$'
        return 0
    endif


    " OTHERWISE, WE NEED TO LOOK FURTHER BACK...

    let prev_codeline_num = s:GetPrevCodeLineNum( a:lnum )
    let prev_codeline = s:FullStripLine( prev_codeline_num )
    let indnt = indent( prev_codeline_num )
    " echom "indnt: " . indnt . " prev_codeline_num: " . prev_codeline_num

    " INCREASE INDENT

    " If the PREVIOUS LINE ended in these items, always indent
    if prev_codeline =~? '\<\(type\|const\|var\)$'
        return indnt + &shiftwidth
    endif

    if prev_codeline =~? '\<repeat$'
        if this_codeline !~? '^until\>'
            return indnt + &shiftwidth
        else
            return indnt
        endif
    endif

    if prev_codeline =~? '\<\(begin\|record\)$'
        if this_codeline !~? '^end\>'
            return indnt + &shiftwidth
        else
            return indnt
        endif
    endif

    " If the PREVIOUS LINE ended with these items, indent if not
    " followed by "begin"
    if prev_codeline =~? '\<\(else\|then\|do\)\|:$'
        if this_codeline !~? '^begin\>'
            return indnt + &shiftwidth
        else
            " If it does start with "begin" then keep the same indent
            "return indnt + &shiftwidth
            return indnt
        endif
    endif

    " TODO: Statement without terminating semicolon (exept if followed by
    " "else")
    
    " DECREASE INDENT

    " Lines starting with "else", but not following line ending with
    " "end".
    if this_codeline =~? '^else\>' && prev_codeline !~? '\<end$'
        return indnt - &shiftwidth
    endif
    

    " Lines after a single-statement branch/loop.
    " Two lines before ended in "then", "else", or "do"
    " Previous line didn't end in "begin"
    let prev2_codeline_num = s:GetPrevCodeLineNum( prev_codeline_num )
    let prev2_codeline = s:FullStripLine( prev2_codeline_num )
    if prev2_codeline =~? '\<\(then\|else\|do\)$' && prev_codeline !~? '\<begin$'
        " If the next code line after a single statement branch/loop
        " starts with "end", "except" or "finally", we need an
        " additional unindentation.
        if this_codeline =~? '^\(end\s*;\|except\|finally\|\)$'
            " Note that we don't return from here.
            return indnt - &shiftwidth - &shiftwidth
        endif
        return indnt - &shiftwidth
    endif

    " Lines starting with "until" or "end". This rule must be overridden
    " by the one for "end" after a single-statement branch/loop. In
    " other words that rule should come before this one.
    if this_codeline =~? '^\(end\|until\)\>'
        return indnt - &shiftwidth
    endif



    " ____________________________________________________________________
    " Object/Borland Pascal/Delphi Extensions
    "
    " Note that extended-pascal is handled here, unless it is simpler to
    " handle them in the standard-pascal section above.


    " COLUMN 1 ALWAYS

    " section headers at start of line.
    if this_codeline =~? '^\(interface\|implementation\|unit\)\>'
        return 0
    endif


    " INDENT ONCE

    " If the PREVIOUS LINE ended in these items, always indent.
    let pat = '^unit\>\|^\('
    let pat .= 'uses\|try\|except\|finally\|interface\|implementation'
    let pat .= '\|private\|protected\|public\|published'
    let pat .= '\)$'
    if prev_codeline =~? pat
        return indnt + &shiftwidth
    endif

    " ???? Indent "procedure" and "functions" if they appear within an
    " class/object definition. But that means overriding standard-pascal
    " rule where these words always go in column 1.


    " UNINDENT ONCE

    if this_codeline =~? '^\(except\|finally\)$'
        return indnt - &shiftwidth
    endif

    if this_codeline =~? '^\(private\|protected\|public\|published\)$'
        return indnt - &shiftwidth
    endif


    " ____________________________________________________________________

    " If nothing changed, return same indent.
    return indnt
endfunction

