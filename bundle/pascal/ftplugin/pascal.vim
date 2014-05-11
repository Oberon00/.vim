if exists('b:did_ft_plugin') || &cp || version < 700
    finish
endif
let b:did_ft_plugin = 1
let b:undo_ftplugin = ''

" {{{ Matchit configuration:
if exists('loaded_matchit')
    let b:match_ignorecase = 1 " (pascal is case-insensitive)

    let b:match_words = '\<\%(begin\|case\|record'
    if exists('pascal_delphi')
        let b:match_words .= '\|object\|class\|try'
    endif
    let b:match_words .= '\)\>'

    if exists('pascal_delphi')
        let b:match_words .= ':\<^\s*\%(except\|finally\)\>'
    endif
    let b:match_words .= ':\<end\>'
    let b:match_words .= ',\<repeat\>:\<until\>'
    let b:match_words .= ',\<if\>:\<else\>'
    " Undo the stuff we changed.
    let b:undo_ftplugin = 'unlet b:match_words|'
endif
" }}}

" Section movement {{{

" Function/procedure keyword followed (optionally) by empty lines or lines
" with more indent than the current one containing the keyword, followed
" by a begin (with any indent).
let s:secPat  = '\v\c%(^(\s*)%(function|procedure)>.+\n'
let s:secPat .= '%(^\1\s+.*\n|\n)*^\s*begin)'

let s:secPat .= '|%(^begin>)|<record>'
if exists('pascal_delphi')
    let s:secPat .= '|<%(class|object)>'
endif
let s:secEndPat = s:secPat . '|%(%$)' " End of file.
let s:secStartPat = s:secPat . '|%(%^)|<%(interface|implementation|unit|program)>'

" Based on http://learnvimscriptthehardway.stevelosh.com/chapters/51.html
function! s:NextSection(toend, backwards, visual)
    if a:visual " Restore visual selection
        silent normal! gv
    endif

    if a:toend && a:backwards
        let lbefore = line('.')
        if lbefore != line('$')
            call s:NextSection(0, 1, 0)
            " Wrapped around || hit top?
            if line('.') > lbefore || line('.') == 1
                call cursor(line('$'), 1)
                return
            endif
        endif
    endif

    let pat = a:toend ? s:secEndPat : s:secStartPat
    let flags = a:backwards ? 'wb' : 'w'
    if a:toend
        let flags .= 'e' " Select the 'begin', so that % works.
    endif

    call search(pat, flags . 's')

    let l = line('.')
    let c = col('.')
    let nl = l
    let nc = c
    while pashgb#IsNonCode(nl, nc)
        call search(pat, flags)
        let nl = line('.')
        let nc = col('.')
        if l == nl && c == nc " Search hit start
            break
        endif
    endwhile

    if a:toend && line('.') != line('$')
        call pashgb#SearchBegEndPair('W')
        let l = line('.')
        if l != line('$') && getline(l + 1) =~# '\v^\s*$'
            silent normal! j
        endif
        silent normal! $
    endif

endfunction

noremap <script> <buffer> <silent> ]]
        \ :call <SID>NextSection(0, 0, 0)<cr>
noremap <script> <buffer> <silent> [[
        \ :call <SID>NextSection(0, 1, 0)<cr>
noremap <script> <buffer> <silent> ][
        \ :call <SID>NextSection(1, 0, 0)<cr>
noremap <script> <buffer> <silent> []
        \ :call <SID>NextSection(1, 1, 0)<cr>

vnoremap <script> <buffer> <silent> ]]
        \ :<c-u>call <SID>NextSection(0, 0, 1)<cr>
vnoremap <script> <buffer> <silent> [[
        \ :<c-u>call <SID>NextSection(0, 1, 1)<cr>
vnoremap <script> <buffer> <silent> ][
        \ :<c-u>call <SID>NextSection(1, 0, 1)<cr>
vnoremap <script> <buffer> <silent> []
        \ :<c-u>call <SID>NextSection(1, 1, 1)<cr>

let b:undo_ftplugin .= 'unmap ]]|unmap [[|unmap ][|unmap []|'

" }}}

" Comments & formatting {{{

setlocal comments=s1:\(*,mb:*,ex:*\)
if exists("pascal_fpc") || exists('pascal_delphi')
    setlocal comments+=://
    setlocal commentstring=//%s
else
    setlocal commentstring=(*%s*)
endif
setlocal formatoptions=tcroq
let b:undo_ftplugin .= 'set comments< commentstring< formatoptions<'

" }}}

" vim: foldmethod=marker
