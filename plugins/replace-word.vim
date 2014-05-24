" File: replace-word.vim
" Author: Christian Neumüller
" Description: Replace the current word or selected text everywhere
" Last Modified: Mai 24, 2014
" Based on http://stackoverflow.com/a/6171215/2128694

" Escape special characters in a string for exact matching.
" This is useful to copying strings from the file to the search tool
" Based on this - http://peterodding.com/code/vim/profile/autoload/xolox/escape.vim
function! s:EscapeString (string)
  let string=a:string
  " Escape only backslah, because we use \V (very no magic)
  let string = escape(string, '\')
  " Escape the line endings
  let string = substitute(string, '\n', '\\n', 'g')
  return string
endfunction

function! s:GetYanked(yankcmd)
  " Save the current register and clipboard
  let reg_save = getreg('"')
  let regtype_save = getregtype('"')
  let cb_save = &clipboard
  set clipboard&

  " Put the inner word in the " register
  exec 'normal! ' . a:yankcmd
  let selection = getreg('"')

  " Put the saved registers and clipboards back
  call setreg('"', reg_save, regtype_save)
  let &clipboard = cb_save

  "Escape any special characters in the selection
  let escaped_selection = s:EscapeString(selection)

  return escaped_selection
endfunction

function! s:GetVisual() range
    return s:GetYanked('""gvy')
endfunction

function! s:GetInnerWord() range
  return s:GetYanked('""yiw')
endfunction

nnoremap <leader>r :%s/\V\C\<<C-r>=<SID>GetInnerWord()<cr>\>//g<left><left>
nnoremap <leader><s-r> :bufdo %s/\V\C\<<C-r>=<SID>GetInnerWord()<cr>\>//g<left><left>
vnoremap <leader>r :<c-u>%s/\V\C<c-r>=<SID>GetVisual()<cr>//g<left><left>
vnoremap <leader><s-r> :<c-u>bufdo %s/\V\C<c-r>=<SID>GetVisual()<cr>//g<left><left>
