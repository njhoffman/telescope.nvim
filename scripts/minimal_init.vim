" Keep the user's config and plugins out of the tests.
for s:dir in [stdpath('config')] + stdpath('config_dirs') + [stdpath('data') . '/site']
      \ + map(stdpath('data_dirs'), {_, dir -> dir . '/site'})
  execute 'set rtp-=' . fnameescape(s:dir)
  execute 'set rtp-=' . fnameescape(s:dir . '/after')
endfor
set packpath=

set rtp+=.
set rtp+=../plenary.nvim/
set rtp+=~/.local/share/nvim/lazy/plenary.nvim/

runtime! plugin/plenary.vim
runtime! plugin/telescope.lua

let g:telescope_test_delay = 100
