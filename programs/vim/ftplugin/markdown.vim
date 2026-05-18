" Prose writing environment for Markdown
" Uses vim-pencil (soft wrap), vim-lexical, vim-litecorrect, vim-textobj-sentence

" Soft wrap — no hard breaks inserted, visual wrapping only
call pencil#init({'wrap': 'soft'})

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
