vim-MakeGreen
=============

makegreen.vim is a vim (http://www.vim.org) plugin that runs make and shows the
test run status with a red or green bar.

Installation
------------

Copy all files to your ~/.vim directory or use Tim Pope's excellent pathogen plugin (http://github.com/tpope/vim-pathogen).

Usage
-----

`:MakeGreen %` will run make for the current file and show its status with a red or green message bar.

example:

    $ cd <your rails/merb root>
    $ vim test/unit/user_test.rb

    :compiler rubyunit
    :MakeGreen %

See [the full documentation] for more.

[the full documentation]: doc/makegreen.txt
