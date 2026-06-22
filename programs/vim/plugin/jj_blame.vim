" jj-aware blame.
"
" vim-fugitive's `:Git blame` needs a .git, which a non-colocated jj workspace
" doesn't have. `:Blame` (and <leader>gb) dispatches: in a jj repo it shows
" `jj file annotate` in a scratch split; otherwise it falls back to fugitive's
" `:Git blame` for plain-git repos.

if exists('g:loaded_jj_blame') | finish | endif
let g:loaded_jj_blame = 1

function! s:err(msg) abort
  echohl ErrorMsg | echo 'blame: ' . a:msg | echohl None
endfunction

" Run from the file's own directory so jj/git resolve the right repo regardless
" of vim's cwd.
function! s:in_jj(dir) abort
  call system('cd ' . shellescape(a:dir) . ' && jj root --ignore-working-copy >/dev/null 2>&1')
  return !v:shell_error
endfunction

function! s:jj_blame() abort
  let l:dir = expand('%:p:h')
  let l:name = expand('%:t')
  if empty(l:name) | call s:err('no file in this buffer') | return | endif
  let l:srcline = line('.')
  let l:out = systemlist('cd ' . shellescape(l:dir)
        \ . ' && jj file annotate --ignore-working-copy -- ' . shellescape(l:name))
  if v:shell_error | call s:err(join(l:out, ' ')) | return | endif

  botright new
  setlocal buftype=nofile bufhidden=wipe noswapfile nowrap nonumber norelativenumber
  call setline(1, l:out)
  setlocal nomodifiable
  " jj annotate line N == source line N, so land on the line you were reading.
  execute 'normal! ' . l:srcline . 'Gzz'
  execute 'resize ' . min([len(l:out) + 1, 20])
  nnoremap <buffer> <silent> q :close<CR>
endfunction

function! s:blame() abort
  if s:in_jj(expand('%:p:h'))
    call s:jj_blame()
  else
    " plain-git repo: hand off to fugitive.
    Git blame
  endif
endfunction

command! Blame call s:blame()
