" Prose writing environment for Markdown
" Uses vim-pencil (soft wrap), vim-lexical, vim-litecorrect, vim-textobj-sentence

" Soft wrap — no hard breaks inserted, visual wrapping only
call pencil#init({'wrap': 'soft'})

" Pencil remaps j/k to gj/gk unconditionally. With relativenumber that breaks
" counted motion (e.g. `3j` jumps 3 display lines, not what the gutter shows).
" Use display-line motion only when no count is given.
nnoremap <buffer> <expr> j v:count ? 'j' : 'gj'
nnoremap <buffer> <expr> k v:count ? 'k' : 'gk'
xnoremap <buffer> <expr> j v:count ? 'j' : 'gj'
xnoremap <buffer> <expr> k v:count ? 'k' : 'gk'

" Spell + dictionary + thesaurus
call lexical#init({
    \ 'spell': 1,
    \ 'spelllang': ['en', 'de'],
    \ })

" Lightweight autocorrect (teh -> the, etc.)
call litecorrect#init()

" Better sentence text objects and motions
call textobj#sentence#init()

" Trim trailing whitespace on save without moving cursor or clobbering search
function! s:TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfunction
autocmd BufWritePre <buffer> call s:TrimWhitespace()

setlocal conceallevel=2
setlocal colorcolumn=
let g:vim_markdown_fenced_languages = ['html', 'python', 'bash=sh', 'go', 'tf=terraform']

" Keep backticks visible so tables (and any monospaced alignment) line up,
" regardless of cursor position. Other conceal (bold/italic markers) stays on.
let g:vim_markdown_conceal_code_blocks = 0

" Make inline code visually distinct: colored fg + dimmed backticks. Use a
" Syntax autocmd because vim-markdown's syntax file loads after this ftplugin
" and would otherwise re-link these groups to String.
augroup markdown_inline_code_hl
    autocmd!
    autocmd Syntax markdown highlight! link mkdCode Special
    autocmd Syntax markdown highlight! link mkdCodeDelimiter Comment
augroup END
