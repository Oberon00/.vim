" Basic settings {{{1
set nocompatible
set encoding=utf-8  " Set utf-8 as default encoding (try recognizing others)
set fileencodings=ucs-bom,utf-8,cp1252
set fileformats=unix,dos,mac  " Unix LF by default (but still can read CRLF)

" Indendation & Tabs {{{
" Indentation is 4 spaces, but (existing) hard tabs still occupy 8 columns.
set shiftwidth=4 softtabstop=4
set expandtab
set shiftround
" }}}


let mapleader = '-'
noremap - <NOP>

filetype plugin indent on
syntax on  " Enable syntax highlighting.
set autoindent  " Keep indentation of last line by default.
set hidden " Just hide buffers when closing all associated windows.

" Allow backspacing over autoindent, line breaks, and start of insert.
set backspace=indent,eol,start
set mouse=a   " Enable mouse in all modes.

"set debug+=msg

let s:has_python = has('python') || has('python3')


augroup myvrc
    au!
augroup END


" Pathogen {{{1

let g:pathogen_disabled = []
if !s:has_python
    call add(g:pathogen_disabled, 'ultisnips')
endif

call pathogen#infect()



" Filetype-specific settings {{{1

function! s:SetPascalOptions()
    setlocal shiftwidth=2 softtabstop=2
    compiler fpcD
endfunction
let g:pascal_delphi = 1
let g:pascal_fpc_mode = 'tp'

function! s:SetPythonOptions()
    setlocal foldmethod=indent
    if has('python3') && (!has('python') || getline(1) =~? 'python3')
        setlocal omnifunc=python3complete#Complete
    endif
    call SuperTabSetDefaultCompletionType("<c-x><c-o>")
endfunction

function! s:SetHtmlOptions()
    nnoremap <buffer> <F5> :<C-U>call xolox#misc#open#file(expand('%'))<CR>
endfunction

augroup myvrc
    au FileType c,cpp call SuperTabSetDefaultCompletionType('<C-P>')
    au FileType cpp setlocal commentstring=//\ %s
    au FileType pascal call <SID>SetPascalOptions()
    let g:tex_flavor = "latex"
    au FileType tex,plaintex setlocal shiftwidth=2 softtabstop=2
    au FileType snippets setlocal noexpandtab tabstop=4
    au FileType vim setlocal foldmethod=marker foldlevel=0
    au FileType python call <SID>SetPythonOptions()
    au FileType markdown setlocal shiftwidth=2 softtabstop=2 foldmethod=indent
    au FileType rst setlocal shiftwidth=2 softtabstop=2 noshiftround
                \            foldmethod=indent indentexpr=
    au FileType html call <SID>SetHtmlOptions()
    au FileType javascript setlocal iskeyword+=$
    au FileType phtml setlocal indentexpr& autoindent
augroup END

set cinoptions+=g0  " Do not indent public/private/protected
set cinoptions+=N-s " Do not indent namespace contents
set cinoptions+=(s  " Indent contents of () only once


" Plugins {{{1

runtime macros/matchit.vim

" CtrlP {{{2
nnoremap <leader>gb :CtrlPBuffer<CR>
nnoremap <leader>gm :CtrlPMRU<CR>
nnoremap <leader>gl :CtrlPLine<CR>
let g:ctrlp_reuse_window = 'startify'

" Startify {{{2
let g:startify_session_persistence = 1
au myvrc User Startified setlocal cursorline

let g:startify_custom_header = []

let g:startify_bookmarks = [{'s': '~/scratch.txt'}]

" UltiSnips {{{2
let g:UltiSnipsEditSplit = 'vertical'
let g:UltiSnipsExpandTrigger = '<C-j>'
let g:UltiSnipsJumpForwardTrigger = '<C-k>'
let g:UltiSnipsJumpBackwardTrigger = '<C-h>'
if has('win32')
    let g:UltiSnipsSnippetsDir = '~/vimfiles/UltiSnips'
endif
let g:snips_author = 'Christian Neumüller'
let g:snips_email = 'cn00@gmx.at'
let g:snips_github = 'Oberon00'

" ipython {{{2
let g:ipy_perform_mappings = 0
let g:ipy_completefunc = 0

" vim-colorscheme-switcher {{{2
let g:colorscheme_switcher_define_mappings = 0

" vim-shell {{{2
let g:shell_mappings_enabled = 0
let g:shell_fullscreen_message = 0
noremap <F11> :<C-U>Fullscreen<CR>
inoremap <F11> <C-O>:<C-U>Fullscreen<CR>

" SuperTab {{{2
let g:SuperTabDefaultCompletionType = 'context'

" Syntastic {{{2
nnoremap <Leader>sy :<C-U>SyntasticCheck<CR>

let g:syntastic_error_symbol = '✘'
let g:syntastic_warning_symbol = '‼'
let g:syntastic_style_error_symbol = '‡'
let g:syntastic_style_warning_symbol = '†'

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

function! s:SetPyChecker()
    let b:syntastic_python_pylint_args =
                \ '--disable=missing-docstring,invalid-name'
    if getline(1) !~# '\<python3\>'
        return
    endif

    if has('win32')
        let pyexe = expand('$SYSTEMDRIVE') . '\Python34\python.exe'
        if executable(pyexe)
            let b:syntastic_python_python_exec = pyexe
        endif
    else
        let b:syntastic_python_python_exec = 'python3'
    endif
endfunction

au myvrc FileType python call <SID>SetPyChecker()

let g:syntastic_html_checkers = ['tidy', 'jshint']
let g:syntastic_mode_map = {
            \ 'passive_filetypes': ['c', 'cpp', 'asm', 'rst']
            \ }

let g:syntastic_lua_checkers = ['luac52', 'luacheck']
let g:syntastic_lua_luac_exec = 'luac52'

let g:lua_check_syntax = 0 " Don't let vim-lua-ftplugin interfere

" Visual settings {{{1

if has('gui_running')
    set guioptions-=m  " Remove menu bar.
    set guioptions-=T  " Remove toolbar.
    if has('win32')
        set guifontwide=NSimSun:h10
        set guifont=Consolas:h10
        if (v:version == 704 && has("patch393")) || v:version > 704
            set renderoptions=type:directx,geom:1
        endif
    endif " if has('win32')
    if &lines < 40
        set lines=40
    endif
    if &columns < 82
        set columns=82
    endif
elseif $TERM =~ '256color'
    set t_ut=
elseif $TERM == 'xterm'
    set t_Co=256  " Force 256 colors.
endif

set guicursor+=n:blinkon0  " No blinking cursor in normal mode.

set shortmess+=I  " No intro-message
set completeopt-=preview

set wildmenu  " Display possible commandline completions.
set showcmd  " Show normal mode commands in bottom line
set showmode " Show mode (INSERT, VISUAL, ...)

set list listchars=trail:·,tab:→\ 
if has('win32') && !has('gui_running')
    set listchars+=nbsp:~,extends:»,precedes:«
    set showbreak=\
else
    set listchars+=nbsp:•,extends:…,precedes:…
    set showbreak=ʅ
endif
if exists('&breakindent')
    set breakindent
endif
set fillchars=vert:│  " Unicode border element
" Use setglobal to not overwrite anything when vimrc is re-sourced.
setglobal foldmethod=syntax foldlevelstart=99
set scrolloff=1  " Keep at least 1 line below/above the cursor visible.
set sidescrolloff=5  "       ... 5 columns left/right ...
set display+=lastline

set hlsearch   " Highlight search matches in whole window...
nohlsearch     " ...but start w/o annoying leftover highlights
set incsearch  " Start highlighting while typing search pattern
" End search highlighting by pressing <Ctrl-L>:
nnoremap <silent> <C-L> :nohlsearch<CR><C-L>


" Color scheme(s) {{{2
function! s:SetDarkBackground()
    set background=dark
    call xolox#colorscheme_switcher#switch_to('gruvbox')
endfunction

function! s:SetLightBackground()
    set background=light
    if has('gui_running') || &t_Co >= 256
        call colorutil#LinkKWOperatorsToOperators()
        call colorutil#LinkStartify()
        call xolox#colorscheme_switcher#switch_to('github')
    endif
endfunction

function! s:ToggleBackground()
    if &background ==? 'light'
        call s:SetDarkBackground()
    else
        call s:SetLightBackground()
    endif
endfunction
noremap <silent> <S-F2> :<C-U>call <SID>ToggleBackground()<CR>
inoremap <silent> <S-F2> <C-O>:<C-U>call <SID>ToggleBackground()<CR>

let g:gruvbox_italicize_comments = 0
let g:gruvbox_italic = 0

augroup myvrc
    au ColorScheme gruvbox
                \   hi! link hsConSym hsVarSym
                \ | hi! link hsVarSym Special
                \ | hi! link ConId Type
                \ | hi! link luaSpecialValue GruvboxOrange
                \ | hi! link luaFuncCall GruvboxBlue
                \ | hi! link luaFuncId GruvboxBlueBold
                \ | call colorutil#LinkKWOperatorsToKWs()
augroup END

call s:SetDarkBackground()

command! -nargs=1 -bar -complete=color Color
            \ call xolox#colorscheme_switcher#switch_to('<args>')

" Statusline {{{1
function! VrcFileInfo() " For statusline below.
    let r = []

    if &fileencoding !=# '' && &fileencoding !=? &encoding
        call add(r, &fileencoding)
    endif

    if &fileformat !=# '' && &fileformat !=? 'unix'
        call add(r, &fileformat)
    endif

    let ext = toupper(expand('%:e'))
    let ft = toupper(&filetype)
    " If filetype is obvious from extension, don't display it
    if ext == '' || stridx(ext, ft) < 0 && stridx(ft, ext) < 0
        call add(r, ft)
    endif

    return join(r, ',')
endfunc

set laststatus=2  " Always show statusbar
set statusline= " Clear statusline, append below:
set statusline+=%4l,%-5(%3v%)  " Line and column position
set statusline+=\ %LL " Total line count (with a literal 'L' appended)
set statusline+=\ %=%<  " Start of right aligned part + truncate here
set statusline+=%{expand('%:~:.')}  "File path
set statusline+=%{SyntasticStatuslineFlag()} " Syntastic
set statusline+=%(\ [%M%R%H%W]%)  " Other flags
set statusline+=%(\ %q%)  " Location/Quickfix window?
set statusline+=%(\ %{fugitive#statusline()}%)  " Git branch/commit
set statusline+=%(\ [%{VrcFileInfo()}]%)  " File info


" Sessions {{{1
set sessionoptions-=options
set sessionoptions+=resize,winpos
set sessionoptions+=unix,slash
nnoremap <silent> <F4> :exec 'SSave ' . fnamemodify(v:this_session, ':t')<CR>



" Foldtext {{{1

let s:foldfill = matchstr(&fillchars, 'fold:\zs.')
if !strlen(s:foldfill)
    let s:foldfill = '-'
endif
let s:metacol = 100

function! VrcGetFoldText()
    let line = getline(v:foldstart)
    let ind = strwidth(matchstr(line, '^\s\+'))
    let foldstartmarker = escape(matchstr(&foldmarker, '[^,]\+'), '\')
    let line = substitute(line, '^\s\+', '', '')
    "let line = substitute(line, '\V' . foldstartmarker . '\d\?\s\*\$', '', '')
    let pfx = '+' . v:folddashes . ' '
    let line = pfx . repeat(' ', ind - strlen(pfx)) . line
    let meta = ' (' . ((v:foldend - v:foldstart) + 1) . ' lines)'
    let occupiedw = strwidth(line) + strwidth(meta)
    if winwidth(0) > s:metacol
        let fill1n = (s:metacol - occupiedw) / strwidth(s:foldfill) - 1
        let fill1  = repeat(s:foldfill, fill1n)
        let occupiedw += strwidth(fill1) + 1
        let fill2n = (winwidth(0) - occupiedw) / strwidth(s:foldfill)
        let fill2  = repeat(s:foldfill, fill2n)
        return line . ' ' . fill1 . meta . ' ' . fill2
    endif
    let filln = (winwidth(0) - occupiedw) / strwidth(s:foldfill)
    let fill = repeat(s:foldfill, filln)
    return line . fill  . meta
endfunction

set foldtext=VrcGetFoldText()



" Other settings {{{1
" chdir to file directory {{{
function! s:EnterDir()
    if expand('%:p:h') !~? '\v/tmp|://|\\\\|\:\:' && expand('%:t') != ''
        try
            lcd %:p:h
        catch /E344/
            " Ignore
        endtry
    endif
endfunc

autocmd myvrc BufEnter * call <SID>EnterDir()

nnoremap <Leader>cd :<C-U>lcd %:p:h<CR>:pwd<CR>
"}}}

" Execute executable named after the current file {{{
if has('win32')
    nnoremap <F5> :<C-U>silent !start cmd /c "%:r.exe" & pause<CR>
else
    if executable('x-terminal-emulator')
        nnoremap <F5> :<C-U>silent !x-terminal-emulator -e bash -c ''\''./%:r'\''; read -p "Finished ($?)."'&<CR>
    else
        nnoremap <F5> :<C-U>!'./%:r'<CR>
    endif
endif
"}}}

nnoremap <F6> :w<CR>:<C-U>make!<CR>:copen<CR><C-W>p
nnoremap <C-K> :cprevious<CR>
nnoremap <C-J> :cnext<CR>

let g:ag_working_path_mode = 'r'
nnoremap <F3> :Ag! '\b<cword>\b'<CR>

""" Open command window/explorer here {{{
if has('win32')
    nnoremap <silent><C-CR> :<C-U>exec 'silent !start ' . &shell<CR>
    nnoremap <silent><C-S-CR> :<C-U>silent !start explorer .<CR>
else
    if executable('x-terminal-emulator')
        nnoremap <silent><C-CR> :<C-U>silent !x-terminal-emulator&<CR>
    endif
    if executable('xdg-open')
        nnoremap <silent><C-S-CR> :<C-U>silent !xdg-open . &<CR>
    endif
endif
" }}}

set textwidth=80
set browsedir=buffer
set ignorecase smartcase
set history=1000

set nrformats-=octal

" wildignore {{{
set wildignore+=*.exe,*.dll " Windows Binaries
set wildignore+=*.so " Linux Binaries
set wildignore+=*.obj,*.tlog,*.lib " MSVC
set wildignore+=*.o,*.a,*.out
set wildignore+=*.ppu " Pascal/FPC
set wildignore+=*.aux,*.out,*.synctex.*,*.toc,*.fls,*.fdb_latexmk,*.pdf " TeX
set wildignore+=*.pyg,*.pygtex,*.pygstyle,_minted-*,.minted*/*,
set wildignore+=*.bbl,*.bcf,*.blg,*.lol,*.lot*,*.run.xml " TeX/biber
set wildignore+=tags,*.swp,.netrwhist,.viminfo,_viminfo " Vim
set wildignore+=*.pyc,*.pyo " Python
set wildignore+=_site,_build " Generated directories
"}}}

" Centralize backups, swapfiles and undo history {{{
let s:vimdir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let s:vimtmpdir = s:vimdir . '/tmp'
"exec 'set backupdir='. s:vimtmpdir . '/backup'
set nobackup
exec 'set directory='. s:vimtmpdir . '/swap//'
exec 'set viewdir='. s:vimtmpdir . '/view/'
if exists('&undodir')
    exec 'set undodir='. s:vimtmpdir . '/undo//'
    set undofile
endif
"}}}

" <C-]> is untypeable on a german keyboard.  Use recursive mapping here because
" we want to use any tag handling overrides by ftplugins and the like.
nmap <CR> <C-]>

" Move up/down by screen lines, not physical lines {{{
noremap j gj
noremap k gk
function! s:DefaultJK()
    nnoremap <buffer> j j
    nnoremap <buffer> k k
endfunction

autocmd myvrc User Startified call <SID>DefaultJK()
"}}}

" Start new, undoable edit before deleting line
inoremap <C-U> <C-G>u<C-U>

" Restore cursor position and folds {{{
set viewoptions=cursor,folds,unix

function! s:IfBufListed(code)
    if !&buflisted
        return
    endif
    exec a:code
endfunction

autocmd myvrc BufWinEnter ?* call <SID>IfBufListed('silent! loadview')
autocmd myvrc BufWinLeave ?* call <SID>IfBufListed('mkview!')
"}}}

" Disable (visual) bell {{{
set visualbell t_vb=
if has('gui_running')
    autocmd myvrc GUIEnter * set t_vb=
endif
"}}}

" Switch buffers {{{
noremap <silent> <F2> :<C-U>buffer #<CR>
inoremap <silent> <F2> <C-O>:<C-U>buffer #<CR>

noremap <silent> <C-Tab> :<C-U>bnext<CR>
inoremap <silent> <C-Tab> <C-O>:<C-U>bnext<CR>
noremap <silent> <C-S-Tab> :<C-U>bprevious<CR>
inoremap <silent> <C-S-Tab> <C-O>:<C-U>bprevious<CR>
"}}}

" Going to files {{{
noremap <leader>gf :<C-U>edit <cfile><CR>

" Idea from http://unix.stackexchange.com/a/74581
function! s:ReuseSplitFile()
    let fname = fnamemodify(findfile(expand('<cfile>')), ':p')
    wincmd w
    execute 'edit ' . fname
endfunction

nnoremap gF :call <SID>ReuseSplitFile()<CR>
""}}}


vnoremap <leader>us :<C-U>'<,'>sort u<CR>

" Remap useless keys {{{
noremap <F1> <Esc>
inoremap <F1> <Esc>
nnoremap Q <Esc>
" }}}

""" Window management mappings {{{
noremap <M-l> <C-W>l
noremap <M-h> <C-W>h
noremap <M-j> <C-W>j
noremap <M-k> <C-W>k
noremap <M-v> <C-W>v
noremap <M-s> <C-W>s
noremap <M-c> <C-W>c
noremap <M-S-H> <C-W>H
noremap <M-S-J> <C-W>J
noremap <M-S-K> <C-W>K
noremap <M-S-L> <C-W>L
" }}}

" Clipboard/yanking/pasting {{{
noremap <leader>p "+p
noremap <leader>P "+P
noremap <leader>y "+y
noremap <leader>Y "+y$
noremap Y y$

" Copy whole buffer to clipboard.
"nnoremap <C-I> gg"+yG
" }}}

if has('win32')
    " Vim seems to interfere with %LANG% lately..
    let $LANG = ''
endif

" Show syntax stack {{{

function! s:DumpSynStack()
    let sstack = synstack(line('.'), col('.'))
    let i = len(sstack)
    for id in reverse(sstack)
        let i -= 1
        let name = synIDattr(id, 'name')
        let tname = synIDattr(synIDtrans(id), 'name')
        let msg = i . ' ' . name
        if name !=# tname
            let msg .= ' -> ' . tname
        endif
        echo msg
    endfor
endfunction

nnoremap <leader>hi :<C-U>call <SID>DumpSynStack()<CR>
" }}}

let g:luasyn_nosymboloperator = 1
let g:luasyn_nofold = 1
let g:luasyn_fold_function = 1
let g:luasyn_fold_table = 1
let g:luasyn_fold_comment = 1
let g:luasyn_fold_string = 1
let g:luasyn_noextendedstdlib = 1

let g:lua_complete_dynamic = 0

" vim: foldmethod=marker
