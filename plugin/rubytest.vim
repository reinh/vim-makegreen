" Vim filetype plugin for running ruby tests
" Last Change: Apr 19 2009
" Maintainer: Jan <jan.h.xie@gmail.com>
" License: MIT License

if exists("rubytest_loaded")
  finish
endif
let rubytest_loaded = 1

if !exists("g:rubytest_cmd_test")
  let g:rubytest_cmd_test = "ruby %p -n '/%c/'"
endif
if !exists("g:rubytest_cmd_spec")
  let g:rubytest_cmd_spec = "spec -f specdoc %p -e '%c'"
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
  let case = s:FindCase(s:test_case_patterns['test'])
  if case != 'false'
    let cmd = substitute(g:rubytest_cmd_test, '%c', case, '')
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
  let case = s:FindCase(s:test_case_patterns['spec'])
  if case != 'false'
    let cmd = substitute(g:rubytest_cmd_spec, '%c', case, '')
    let cmd = substitute(cmd, '%p', @%, '')
    exe "!echo '" . cmd . "' && " . cmd
  else
    echo 'No spec found.'
  end
endfunction

let s:test_patterns = {}
let s:test_patterns['_test.rb$'] = function('s:RunTest')
let s:test_patterns['_spec.rb$'] = function('s:RunSpec')

function s:GetTestCaseName1(str)
  return split(str)[1]
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

function s:IsRubyTest()
  for pattern in keys(s:test_patterns)
    if @% =~ pattern
      let s:pattern = pattern
      return 1
    endif
  endfor
endfunction

function s:Run()
  if &filetype != "ruby"
    echo "This file doens't contain ruby source."
  elseif !s:IsRubyTest()
    echo "This file doesn't contain ruby test."
  else
    call s:test_patterns[s:pattern]()
  endif
endfunction

noremap <unique> <script> <Plug>RubyTestRun <SID>Run
noremap <SID>Run :call <SID>Run()<CR>

let &cpo = s:save_cpo
