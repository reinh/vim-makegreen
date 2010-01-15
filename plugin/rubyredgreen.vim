" plugin/rubyredgreen.vim
" Author:   Rein Henrichs <reinh@reinh.com>
" License:  MIT License

" Install this file as plugin/rubyredgreen.vim.

" ============================================================================

" Exit quickly when:
" - this plugin was already loaded (or disabled)
" - when 'compatible' is set
if &cp || exists("g:rubyredgreen_loaded") && g:rubyredgreen_loaded
  finish
endif
let g:rubyredgreen_loaded = 1

let s:save_cpo = &cpo
set cpo&vim

function s:RunTests() "{{{1
  " should be ftplugin?
  if &filetype != "ruby"
    return 0
  endif

  let cmd = s:GetTestCmd()
  if cmd == ''
    echo "This file doesn't contain ruby tests"
    return 0
  endif

  call s:RubyCex(cmd)

  let error = s:GetFirstError()
  if error != ''
    silent cc!
    call s:RedBar(error)
  else
    call s:GreenBar()
  endif
endfunction
"}}}1
" Utility Functions" {{{1
function s:EscapeBackSlash(str)
  return substitute(a:str, '\', '\\\\', 'g') 
endfunction

function s:GetTestCmd()
  let test_patterns = {}
  let test_patterns['_test.rb$'] = "ruby %p"
  let test_patterns['_spec.rb$'] = "spec -f specdoc %p"

  for [pattern, cmd] in items(test_patterns)
    if @% =~ pattern
      return substitute(cmd, '%p', s:EscapeBackSlash(@%), '')
    endif
  endfor
  return ''
endfunction

function s:GetFirstError()
  if getqflist() == []
    return ''
  endif

  for error in getqflist()
    if error['valid']
      break
    endif
  endfor
  let error_message = substitute(error['text'], '^ *', '', 'g')
  let error_message = substitute(error_message, "\n", ' ', 'g')
  let error_message = substitute(error_message, "  *", ' ', 'g')
  return error_message
endfunction

function s:EchonPadded(msg)
  echon a:msg
  echon repeat(" ", &columns - strlen(a:msg))
endfunction

function s:RedBar(msg)
    hi RedBar term=reverse ctermfg=white ctermbg=red guifg=white guibg=red
    echohl RedBar
    call s:EchonPadded(a:msg)
    echohl
endfunction

function s:GreenBar()
    hi GreenBar term=reverse ctermfg=white ctermbg=green guifg=white guibg=green
    echohl GreenBar
    call s:EchonPadded('All tests passed')
    echohl
endfunction

function s:RubyCex(cmd)
  let oldefm = &efm
  let &efm = s:efm . s:efm_backtrace . ',' . s:efm_ruby . ',' . oldefm . ',%-G%.%#'
  silent cex system(a:cmd)
  let &efm = oldefm
endfunction

" }}}1
" Error formats" {{{1
let s:efm='%-G%\\d%\\+)%.%#,'

" below errorformats are copied from rails.vim
" Current directory
let s:efm=s:efm . '%D(in\ %f),'
" Failure and Error headers, start a multiline message
let s:efm=s:efm
      \.'%A\ %\\+%\\d%\\+)\ Failure:,'
      \.'%A\ %\\+%\\d%\\+)\ Error:,'
      \.'%+A'."'".'%.%#'."'".'\ FAILED,'
" Exclusions
let s:efm=s:efm
      \.'%-C%.%#(eval)%.%#,'
      \.'%-C-e:%.%#,'
      \.'%-C%.%#/lib/gems/%\\d.%\\d/gems/%.%#,'
      \.'%-C%.%#/lib/ruby/%\\d.%\\d/%.%#,'
      \.'%-C%.%#/vendor/rails/%.%#,'
" Specific to template errors
let s:efm=s:efm
      \.'%C\ %\\+On\ line\ #%l\ of\ %f,'
      \.'%CActionView::TemplateError:\ compile\ error,'
" stack backtrace is in brackets. if multiple lines, it starts on a new line.
let s:efm=s:efm
      \.'%Ctest_%.%#(%.%#):%#,'
      \.'%C%.%#\ [%f:%l]:,'
      \.'%C\ \ \ \ [%f:%l:%.%#,'
      \.'%C\ \ \ \ %f:%l:%.%#,'
      \.'%C\ \ \ \ \ %f:%l:%.%#]:,'
      \.'%C\ \ \ \ \ %f:%l:%.%#,'
" Catch all
let s:efm=s:efm
      \.'%Z%f:%l:\ %#%m,'
      \.'%Z%f:%l:,'
      \.'%C%m,'
" Syntax errors in the test itself
let s:efm=s:efm
      \.'%.%#.rb:%\\d%\\+:in\ `load'."'".':\ %f:%l:\ syntax\ error\\\, %m,'
      \.'%.%#.rb:%\\d%\\+:in\ `load'."'".':\ %f:%l:\ %m,'
" And required files
let s:efm=s:efm
      \.'%.%#:in\ `require'."'".':in\ `require'."'".':\ %f:%l:\ syntax\ error\\\, %m,'
      \.'%.%#:in\ `require'."'".':in\ `require'."'".':\ %f:%l:\ %m,'
" Exclusions
let s:efm=s:efm
      \.'%-G%.%#/lib/gems/%\\d.%\\d/gems/%.%#,'
      \.'%-G%.%#/lib/ruby/%\\d.%\\d/%.%#,'
      \.'%-G%.%#/vendor/rails/%.%#,'
      \.'%-G%.%#%\\d%\\d:%\\d%\\d:%\\d%\\d%.%#,'
" Final catch all for one line errors
let s:efm=s:efm
      \.'%-G%\\s%#from\ %.%#,'
      \.'%f:%l:\ %#%m,'

let s:efm_backtrace='%D(in\ %f),'
      \.'%\\s%#from\ %f:%l:%m,'
      \.'%\\s#{RAILS_ROOT}/%f:%l:\ %#%m,'
      \.'%\\s%#[%f:%l:\ %#%m,'
      \.'%\\s%#%f:%l:\ %#%m'

let s:efm_ruby='\%-E-e:%.%#,\%+E%f:%l:\ parse\ error,%W%f:%l:\ warning:\ %m,%E%f:%l:in\ %*[^:]:\ %m,%E%f:%l:\ %m,%-C%\tfrom\ %f:%l:in\ %.%#,%-Z%\tfrom\ %f:%l,%-Z%p^'
" }}}1
" Mappings" {{{1
noremap <unique> <script> <Plug>RubyFileRun <SID>RunFile
noremap <SID>RunFile :call <SID>RunTests()<CR>

if !hasmapto('<Plug>RubyFileRun')
  map <unique> <silent> <Leader>t <Plug>RubyFileRun
endif
" }}}1

let &cpo = s:save_cpo

" vim:set sw=2 sts=2:
