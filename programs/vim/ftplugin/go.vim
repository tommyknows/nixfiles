nmap <leader>x :wa<CR>:!go run .<CR>
nmap <leader>t :wa<CR>:!go test ./...<CR>
nmap <leader>tv :wa<CR>:!go test -v ./...<CR>
nmap <leader>c :GoCoverage toggle<CR>

" wide lines in Go
set colorcolumn=100
set textwidth=100

let g:gopher_setup = ['no-vendor-gobin']
let g:gopher_debug = ['setup']
nnoremap ; :
" Show tab characters in go as |
set listchars=tab:\|\ ,trail:·

set foldmethod=syntax
let g:gopher_highlight = ['string-spell', 'string-fmt', 'fold-block', 'fold-import', 'fold-pkg-comment', 'fold-varconst']
" this is somehow needed to get folding to work...
set syntax=go

let g:gopher_map._nmap_prefix = '.'
let g:gopher_map._imap_prefix = '<C-g>'

let g:coc_snippet_next = '<c-h>'
let g:coc_snippet_prev = '<c-t>'

" always open the quickfix list
"let g:ale_open_list = 1
"
"" only run the fast linters and on the whole package
"let g:ale_go_golangci_lint_options = '--fast'
"let g:ale_go_golangci_lint_package=1
"let g:ale_go_gofmt_options = '-s'

command! -nargs=* -bang GoTest call go#test#Test(<bang>0, 0, <f-args>)
command! -nargs=* -bang GoTestFunc call go#test#Func(<bang>0, <f-args>)
command! -nargs=* -bang GoTestCompile call go#test#Test(<bang>0, 1, <f-args>)

" for some reason, this isn't silent & doesn't sort the imports...
autocmd BufWritePre *.go :silent call CocAction('runCommand', 'editor.action.organizeImport')
