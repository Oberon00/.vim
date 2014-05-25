" Basic settings {{{1
set nocompatible

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

" Encoding and tabs {{{1

set encoding=utf-8  " Set utf-8 as default encoding (try recognizing others)
set fileencodings=ucs-bom,utf-8,cp1252
set fileformats=unix,dos,mac  " Unix LF by default (but still can read CRLF)
set fileformat=unix  " For new files, use Unix LF

" Indentation is 4 spaces, but (existing) hard tabs still occupy 8 columns.
set shiftwidth=4
set softtabstop=4
set expandtab

" Pathogen {{{1
let g:pathogen_disabled = []
if has('win32')
    " vim-ipython is too much trouble on windows. I'm affected by
    " https://github.com/ivanov/vim-ipython/issues/20 (which can be fixed) and
    " http://bugs.python.org/issue17213 (which is very annoying).
    call add(g:pathogen_disabled, 'vim-ipython')
endif
call pathogen#infect()


" Filetype-specific settings {{{1

function! s:SetPascalOptions()
    setlocal shiftwidth=2 softtabstop=2 textwidth=82
    compiler fpcD
endfunction
let g:pascal_delphi = 1
let g:pascal_fpc_mode = 'tp'

function! s:SetTexOptions()
    setlocal shiftwidth=2 softtabstop=2 textwidth=82
    nnoremap <buffer> <F6> :<C-U>w<CR>:<C-U>Latexmk<CR>
    nnoremap <buffer> <F5> :<C-U>LatexView<CR>
endfunction

augroup vrcFiletypes
    autocmd!
    autocmd FileType pascal call <SID>SetPascalOptions()
    autocmd FileType tex,plaintex call <SID>SetTexOptions()
    autocmd FileType snippets setlocal noexpandtab tabstop=4
    autocmd FileType vim setlocal foldmethod=marker foldlevel=0
    autocmd FileType python setlocal foldmethod=indent
augroup END

set cinoptions+=g0 " Do not indent public/private/protected


" Plugins {{{1

runtime macros/matchit.vim

" Unite {{{2
nnoremap <Leader>f :<C-U>Unite -start-insert file<CR>
nnoremap <Leader>rf :<C-U>Unite -start-insert file_rec<CR>
nnoremap <Leader>b :<C-U>Unite buffer<CR>
nnoremap <Leader>l :<C-U>Unite -start-insert -no-split line<CR>

" LaTeXBox {{{2
if !has('win32')
    " On windows this only works when patching latexmk.vim to use !start /min
    " instead of !start /b.
    " TODO: Try to reproduce on other machine and/or file bug.
    let g:LatexBox_latexmk_async = 1
endif
" Potentially dangerous but necessary for the minted package.
let g:LatexBox_latexmk_options = '-latexoption=-shell-escape'
let g:tex_flavor = "latex"

" UltiSnips {{{2
let g:UltiSnipsEditSplit = 'vertical'
let g:UltiSnipsExpandTrigger = '<C-j>'
let g:UltiSnipsJumpForwardTrigger = '<C-k>'
let g:UltiSnipsJumpBackwardTrigger = '<C-h>'
if has('win32')
    let g:UltiSnipsSnippetsDir = '~/vimfiles/UltiSnips'
endif

" ipython {{{2
let g:ipy_perform_mappings = 0
let g:ipy_completefunc = 0
" Visual settings: {{{1

if has('gui_running')
    set guioptions-=m  " Remove menu bar.
    set guioptions-=T  " Remove toolbar.
    if has('win32')
        set guifont=Consolas:h10
        set guifontwide=NSimSun:h10
    endif " if has('win32')
    if &lines < 40
        set lines=40
    endif
elseif $TERM == 'xterm'
    set t_Co=256  " Force 256 colors.
endif

set guicursor=n:blinkon0  " No blinking cursor in normal mode.

set shortmess+=I  " No intro-message
set completeopt-=preview

set wildmenu  " Display possible commandline completions.
set showcmd  " Show normal mode commands in bottom line
set showmode

set hlsearch   " Highlight search matches in whole window...
nohlsearch     " ...but start w/o annoying leftover highlights
set incsearch  " Start highlighting while typing search pattern
" End search highlighting by pressing <Esc>:
nnoremap <silent> <Esc> :nohlsearch<Return>

" Color scheme(s) {{{2
function! s:SetDarkBackground()
    set background=dark
    let g:gruvbox_contrast = 'soft'
    hi! link pascalOperator Keyword
    hi! link luaOperator Keyword
    silent! colorscheme gruvbox
endfunction

function! s:SetLightBackground()
    set background=light
    if has('gui_running') " Sadly, ironman is only available for gVim
        hi! link pascalOperator Operator
        hi! link luaOperator Operator
        silent! colorscheme ironman
    else
        let g:gruvbox_contrast = 'hard'
        hi! link pascalOperator Keyword
        hi! link luaOperator Keyword
        silent! colorscheme gruvbox
    endif
endfunction

function! s:ToggleBackground()
    if &background ==? 'light'
        call s:SetDarkBackground()
    else
        call s:SetLightBackground()
    endif
endfunction
noremap <silent> <F2> :<C-U>call <SID>ToggleBackground()<CR>

call s:SetDarkBackground() " Start with the dark background
let s:use_italics = has('gui_running') || $TERM != 'xterm'
let g:gruvbox_italicize_comments = 0
let g:gruvbox_italicize_strings = s:use_italics




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
set statusline+=%4l,%-5(%02c%03V%)  " Line and column position
set statusline+=\ %=%<  " Start of right aligned part + truncate here
set statusline+=%{expand('%:~:.')}  "File path
set statusline+=\ %LL " Total line count (with a literal 'L' appended)
set statusline+=%(\ [%M%R%H%W]%)  " Other flags
set statusline+=%(\ %q%)  " Location/Quickfix window?
set statusline+=%(\ [%{VrcFileInfo()}]%)  " File info


" Sessions {{{1
function! s:MkSession()
    if v:this_session ==# ''
        if filewritable('Session.vsess')
            echo 'Session.vsess already exists. Overwrite? (y/n)'
            if nr2char(getchar()) ==? 'y'
                mksession! Session.vsess
                echo 'Session.vsess overwritten.'
            else
                echo 'Cancelled saving session.'
            endif
        else
            mksession Session.vsess
            echo 'Saved as new file Session.vsess.'
        endif
    else
        exec 'mksession! ' . v:this_session
        echo 'Saved ' . v:this_session . '.'
    endif
endfunction

set sessionoptions-=options
set sessionoptions+=resize,winpos
set sessionoptions+=unix,slash
nnoremap <silent> <F4> :call <SID>MkSession()<CR>

" Other settings {{{1

" chdir to file directory {{{
function! s:EnterDir()
    if expand('%:p:h') !~? '\v/tmp|\\\\|\:\:' && expand('%:t') != ''
        try
            lcd %:p:h
        catch /E344/
            " Ignore
        endtry
    endif
endfunc

augroup vrcMisc
    autocmd!
    autocmd BufEnter * call <SID>EnterDir()
augroup END

nnoremap <Leader>cd :<C-U>lcd %:p:h<CR>:pwd<CR>
"}}}

" Execute executable named after the current file {{{
if has('win32')
    nnoremap <F5> :<C-U>silent !start cmd /c "%:r.exe" & pause<CR>
else
    nnoremap <F5> :<C-U>!'%:r'<CR>
endif
"}}}

nnoremap <F6> :w<CR>:<C-U>make!<CR>:copen<CR><C-W>p

if has('win32')
    nnoremap <silent><C-CR> :<C-U>exec 'silent !start ' . &shell<CR>
    nnoremap <silent><C-S-CR> :<C-U>silent !start explorer .<CR>
endif

set browsedir=buffer
set clipboard=unnamed
set ignorecase smartcase
set history=1000
" Use setglobal to not overwrite anything when vimrc is re-sourced.
setglobal foldmethod=syntax foldlevelstart=99
set scrolloff=1  " Keep at least 1 line below/above the cursor visible.
set sidescrolloff=5  "       ... 5 columns left/right ...

" Centralize backups, swapfiles and undo history {{{
let s:vimdir = has('win32') ? '~/vimfiles' : '~/.vim'
exec 'set backupdir='. s:vimdir . '/backup'
exec 'set directory='. s:vimdir . '/swap'
if exists("&undodir")
    exec 'set undodir='. s:vimdir . '/undo'
endif
"}}}

" <C-]> is untypeable on a german keyboard.
nnoremap <CR> <C-]>


" vim: foldmethod=marker
