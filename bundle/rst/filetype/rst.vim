" File: rst.vim
" Author: Christian Neumüller
" Description: Enhanchments to the rst plugin.
" Last Modified: September 17, 2014

if exists('b:did_ftplugin') || &cp || version < 700
    finish
endif
let b:did_ftplugin = 1

setlocal suffixesadd=.rst,.rest,.restx,.txt

let b:undo_ftplugin='set suffixesadd<'
