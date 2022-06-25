" SpellCheck in Markdown files. Hover over a word and press zg to add word
" to spell list
" `set nospell` to disable
setlocal spell
"set spelllang=
setlocal spelllang=en,de
setlocal conceallevel=2
let g:vim_markdown_fenced_languages = ['html', 'python', 'bash=sh', 'go', 'tf=terraform']
set textwidth=80
set colorcolumn=80

autocmd BufWritePre *.md :%s/\s\+$//e
