set nocompatible
scriptencoding utf-8

let mapleader = '-'
noremap - <NOP>
"set debug+=msg

" ---------------------------------------------------------------------------
" Fileformat settings: {{{

set encoding=utf-8  " Set utf-8 as default encoding (try recognizing others)
set fileencodings=ucs-bom,utf-8,cp1252
set fileformats=unix,dos,mac  " Unix LF by default (but still can read CRLF)
set fileformat=unix  " For new files, use Unix LF

" Indentation is 4 spaces, but (existing) hard tabs still occupy 8 columns.
set shiftwidth=4
set softtabstop=4
set expandtab

" }}}

let g:pathogen_disabled = []
if has('win32')
    " vim-ipython is too much trouble on windows. I'm affected by
    " https://github.com/ivanov/vim-ipython/issues/20 (which can be fixed) and
    " http://bugs.python.org/issue17213 (which is very annoying).
    call add(g:pathogen_disabled, 'vim-ipython')
endif
call pathogen#infect()

" ---------------------------------------------------------------------------
" Editing features: {{{

filetype on         " Enable filetype detection
filetype plugin on  " Enable plugins for filetypes
filetype indent on  " Enable loading indent scripts for recognized filetypes
set autoindent  " Keep indentation of last line by default

" Allow backspacing over autoindent, line breaks, and start of insert.
set backspace=indent,eol,start

function! s:SetPascalOptions()
    setlocal shiftwidth=2
    setlocal softtabstop=2
    compiler fpcD
endfunction

function! s:SetTexOptions()
    setlocal shiftwidth=2
    setlocal softtabstop=2
    nnoremap <buffer> <F6> :<C-U>w<CR>:<C-U>Latexmk<CR>
    nnoremap <buffer> <F5> :<C-U>LatexView<CR>
endfunction

augroup vrcFiletypes
    autocmd!
    autocmd FileType pascal call <SID>SetPascalOptions()
    autocmd FileType tex,plaintex call <SID>SetTexOptions()
    autocmd FileType snippets setlocal noexpandtab tabstop=4
augroup END

runtime macros/matchit.vim

set history=200

" }}}

" ---------------------------------------------------------------------------
" UltiSnips configuration: {{{

let g:UltiSnipsEditSplit = 'vertical'
let g:UltiSnipsExpandTrigger = '<C-j>'
let g:UltiSnipsJumpForwardTrigger = '<C-k>'
let g:UltiSnipsJumpBackwardTrigger = '<C-h>'
if has('win32')
    let g:UltiSnipsSnippetsDir = '~/vimfiles/UltiSnips'
endif

" }}}

" ---------------------------------------------------------------------------
" Visual settings: {{{

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

syntax on  " Enable syntax highlighting

" Color scheme:
function! s:SetDarkBackground()
    let g:gruvbox_contrast = 'soft'
    set background=dark  " Use default dark color theme by default
endfunction

function! s:SetLightBackground()
    let g:gruvbox_contrast = 'hard'
    set background=light
endfunction

function! s:ToggleBackground()
    if &background ==# 'light'
        call s:SetDarkBackground()
    else
        call s:SetLightBackground()
    endif
endfunction
noremap <silent> <F2> :<C-U>call <SID>ToggleBackground()<CR>

call s:SetDarkBackground()
let s:use_italics = has('gui_running') || $TERM != 'xterm'
let g:gruvbox_italicize_comments = 0
let g:gruvbox_italicize_strings = s:use_italics
hi! link pascalOperator Keyword
hi! link luaOperator Keyword
silent! colorscheme gruvbox

set scrolloff=1  " Keep at least 1 line below/above the cursor visible.
set sidescrolloff=5  "       ... 5 columns left/right ...

set wildmenu  " Display possible commandline completions.
set showcmd  " Show normal mode commands in bottom line

set hlsearch   " Highlight search matches in whole window...
nohlsearch     " ...but start w/o annoying leftover highlights
set incsearch  " Start highlighting while typing search pattern
" End search highlighting by pressing <Esc>:
nnoremap <silent> <Esc> :nohlsearch<Return>

set clipboard=unnamed

" }}}

" ---------------------------------------------------------------------------

" }}}

" ---------------------------------------------------------------------------
" Other settings: {{{

" chdir to file directory:
function! s:EnterDir()
    if expand('%:p:h') !~? '\v/tmp|\\\\' && expand('%:t') != ''
        lcd %:p:h
    endif
endfunc

nnoremap <Leader>cd :<C-U>lcd %:p:h<CR>:pwd<CR>
augroup vrcMisc
    autocmd!
    autocmd BufEnter * call <SID>EnterDir()
augroup END

" Execute executable generated from file
if has('win32')
    nnoremap <F5> :<C-U>!start cmd /c "%:r.exe" & pause<CR>
else
    nnoremap <F5> :<C-U>!'%:r'<CR>
endif

nnoremap <F6> :w<CR>:<C-U>make!<CR>:copen<CR><C-W>p
nnoremap <Leader>j :<C-U>cnext<CR>
nnoremap <Leader>k :<C-U>cprevious<CR>

if has('win32')
    nnoremap <silent><C-CR> :<C-U>exec 'silent !start ' . &shell<CR>
    nnoremap <silent><C-S-CR> :<C-U>silent !start explorer .<CR>
endif


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

set mouse=a   " Enable mouse in all modes.

set shortmess+=I  " No intro-message

set ignorecase
set smartcase

set completeopt-=preview

nnoremap <Leader>f :<C-U>Unite -start-insert file<CR>
nnoremap <Leader>rf :<C-U>Unite -start-insert file_rec<CR>
nnoremap <Leader>b :<C-U>Unite buffer<CR>
nnoremap <Leader>l :<C-U>Unite -start-insert -no-split line<CR>


if !has('win32')
    " On windows this only works when patching latexmk.vim to use !start /min
    " instead of !start /b.
    " TODO: Try to reproduce on other machine and/or file bug.
    let g:LatexBox_latexmk_async = 1
endif
" Potentially dangerous but necessary for the minted package.
let g:LatexBox_latexmk_options = '-latexoption=-shell-escape'
let g:tex_flavor = "latex"


set hidden

" Centralize backups, swapfiles and undo history
let s:vimdir = has('win32') ? '~/vimfiles' : '~/.vim'
exec 'set backupdir='. s:vimdir . '/backup'
exec 'set directory='. s:vimdir . '/swap'
if exists("&undodir")
    exec 'set undodir='. s:vimdir . '/undo'
endif
" }}}

" <C-]> is untypeable on a german keyboard.
nnoremap <CR> <C-]>

let g:ipy_perform_mappings = 0
let g:ipy_completefunc = 0

