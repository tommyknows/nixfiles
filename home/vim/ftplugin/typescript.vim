set expandtab
setlocal shiftwidth=2
setlocal tabstop=2
" Default of prettier, it will format the code automatically.
" This makes formatting the comments easier.
setlocal textwidth=80
setlocal colorcolumn=80

nnoremap <leader>jt :call CocAction('runCommand', 'jest.singleTest')<CR>
nnoremap <leader>jf :call CocAction('runCommand', 'jest.fileTest')<CR>
nnoremap <leader>jp :call CocAction('runCommand', 'jest.projectTest')<CR>

let g:indentLine_enabled = 1
