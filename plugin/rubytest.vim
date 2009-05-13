" Vim plugin for running ruby tests
" Last Change: May 13 2009
" Maintainer: Jan <jan.h.xie@gmail.com>
" License: MIT License

if exists("rubytest_loaded")
  finish
endif
let rubytest_loaded = 1

if !exists("g:rubytest_in_quickfix")
  let g:rubytest_in_quickfix = 1
endif
if !exists("g:rubytest_cmd_test")
  let g:rubytest_cmd_test = "ruby %p"
endif
if !exists("g:rubytest_cmd_testcase")
  let g:rubytest_cmd_testcase = "ruby %p -n '/%c/'"
endif
if !exists("g:rubytest_cmd_spec")
  let g:rubytest_cmd_spec = "spec -f specdoc %p"
endif
if !exists("g:rubytest_cmd_example")
  let g:rubytest_cmd_example = "spec -f specdoc %p -e '%c'"
endif

function s:FindCase(patterns)
  let ln = a:firstline
  while ln > 0
    let line = getline(ln)
    for pattern in keys(a:patterns)
      if line =~ pattern
        return a:patterns[pattern](line)
      endif
    endfor
    let ln -= 1
  endwhile
  return 'false'
endfunction

function s:RunTest()
  if s:test_scope == 1
    let cmd = g:rubytest_cmd_testcase
  elseif s:test_scope == 2
    let cmd = g:rubytest_cmd_test
  end

  let case = s:FindCase(s:test_case_patterns['test'])
  if case != 'false'
    let cmd = substitute(cmd, '%c', case, '')
    if @% =~ '^test'
      let cmd = substitute(cmd, '%p', strpart(@%,5), '')
      exe "!echo '" . cmd . "' && cd test && " . cmd
    else
      let cmd = substitute(cmd, '%p', @%, '')
      exe "!echo '" . cmd . "' && " . cmd
    end
  else
    echo 'No test case found.'
  endif
endfunction

function s:RunSpec()
  if s:test_scope == 1
    let cmd = g:rubytest_cmd_example
  elseif s:test_scope == 2
    let cmd = g:rubytest_cmd_spec
  endif

  let case = s:FindCase(s:test_case_patterns['spec'])
  if case != 'false'
    let cmd = substitute(cmd, '%c', case, '')
    let cmd = substitute(cmd, '%p', @%, '')
    if g:rubytest_in_quickfix > 0
      let s:oldefm = &efm
      let &efm = s:efm . s:efm_backtrace . ',' . s:efm_ruby . ',' . s:oldefm . ',%-G%.%#'

      cex system(cmd)
      cw

      let &efm = s:oldefm
    else
      exe "!echo '" . cmd . "' && " . cmd
    endif
  else
    echo 'No spec found.'
  endif
endfunction

let s:test_patterns = {}
let s:test_patterns['_test.rb$'] = function('s:RunTest')
let s:test_patterns['_spec.rb$'] = function('s:RunSpec')

function s:GetTestCaseName1(str)
  return split(a:str)[1]
endfunction

function s:GetTestCaseName2(str)
  return "test_" . join(split(split(a:str, '"')[1]), '_')
endfunction

function s:GetTestCaseName3(str)
  return split(a:str, '"')[1]
endfunction

function s:GetSpecName1(str)
  return split(a:str, '"')[1]
endfunction

let s:test_case_patterns = {}
let s:test_case_patterns['test'] = {'^\s*def test':function('s:GetTestCaseName1'), '^\s*test \s*"':function('s:GetTestCaseName2'), '^\s*should \s*"':function('s:GetTestCaseName3')}
let s:test_case_patterns['spec'] = {'^\s*it \s*"':function('s:GetSpecName1')}

let s:save_cpo = &cpo
set cpo&vim

if !hasmapto('<Plug>RubyTestRun')
  map <unique> <Leader>t <Plug>RubyTestRun
endif
if !hasmapto('<Plug>RubyFileRun')
  map <unique> <Leader>T <Plug>RubyFileRun
endif

function s:IsRubyTest()
  for pattern in keys(s:test_patterns)
    if @% =~ pattern
      let s:pattern = pattern
      return 1
    endif
  endfor
endfunction

function s:Run(scope)
  if &filetype != "ruby"
    echo "This file doens't contain ruby source."
  elseif !s:IsRubyTest()
    echo "This file doesn't contain ruby test."
  else
    " test scope define what to test
    " 1: test case under cursor
    " 2: all tests in file
    let s:test_scope = a:scope
    call s:test_patterns[s:pattern]()
  endif
endfunction

noremap <unique> <script> <Plug>RubyTestRun <SID>Run
noremap <unique> <script> <Plug>RubyFileRun <SID>RunFile
noremap <SID>Run :call <SID>Run(1)<CR>
noremap <SID>RunFile :call <SID>Run(2)<CR>

let s:efm='%A%\\d%\\+)%.%#,'

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
