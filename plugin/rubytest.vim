" Vim plugin for running ruby tests
" Last Change: May 13 2009
" Maintainer: Jan <jan.h.xie@gmail.com>
" License: MIT License

if exists("rubytest_loaded")
  finish
endif
let rubytest_loaded = 1

if !exists("g:rubytest_cmd_test")
  let g:rubytest_cmd_test = "ruby %p"
endif
if !exists("g:rubytest_cmd_spec")
  let g:rubytest_cmd_spec = "spec -f specdoc %p"
endif

function s:EscapeBackSlash(str)
  return substitute(a:str, '\', '\\\\', 'g') 
endfunction

function s:RunSpec()
  let cmd = g:rubytest_cmd_spec

    let cmd = substitute(cmd, '%p', s:EscapeBackSlash(@%), '')

    let s:oldefm = &efm
    let &efm = s:efm . s:efm_backtrace . ',' . s:efm_ruby . ',' . s:oldefm . ',%-G%.%#'
    cex system(cmd)
    let &efm = s:oldefm
endfunction

let s:test_patterns = {}
let s:test_patterns['_test.rb$'] = function('s:RunTest')
let s:test_patterns['_spec.rb$'] = function('s:RunSpec')

let s:save_cpo = &cpo
set cpo&vim

function s:IsRubyTest()
  for pattern in keys(s:test_patterns)
    if @% =~ pattern
      let s:pattern = pattern
      return 1
    endif
  endfor
endfunction

" TESTING RED GREEN BAR
function! JumpToError()
    if getqflist() != []
        for error in getqflist()
            if error['valid']
                break
            endif
        endfor
        let error_message = substitute(error['text'], '^ *', '', 'g')
        let error_message = substitute(error_message, "\n", ' ', 'g')
        let error_message = substitute(error_message, "  *", ' ', 'g')
        silent cc!
        call s:RedBar(error_message)
    else
        call s:GreenBar()
    endif
endfunction

function s:EchonPadded(msg)
  echon a:msg
  echon repeat(" ",&columns - strlen(a:msg))
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

function s:RunFile()
  if &filetype != "ruby"
    echo "This file doens't contain ruby source."
  elseif !s:IsRubyTest()
    echo "This file doesn't contain ruby test."
  else
    call s:test_patterns[s:pattern]()
  endif
endfunction

noremap <unique> <script> <Plug>RubyFileRun <SID>RunFile
noremap <SID>RunFile :call <SID>RunFile()<CR>

if !hasmapto('<Plug>RubyFileRun')
  map <unique> <silent> <Leader>t <Plug>RubyFileRun<cr>:redraw<cr>:call JumpToError()<cr>
endif

" Error formats
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
      \.'%C%.%#(eval)%.%#,'
      \.'%C-e:%.%#,'
      \.'%C%.%#/lib/gems/%\\d.%\\d/gems/%.%#,'
      \.'%C%.%#/lib/ruby/%\\d.%\\d/%.%#,'
      \.'%C%.%#/vendor/rails/%.%#,'
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

let &cpo = s:save_cpo
