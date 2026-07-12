" jj-aware blame, fugitive-style.
"
" vim-fugitive's `:Git blame` needs a .git, which a non-colocated jj workspace
" doesn't have. `:Blame` (and <leader>gb) dispatches: in a jj repo it opens a
" narrow blame column (change-id, author, date from `jj file annotate`) in a
" left split, scroll- and cursor-bound to the source, fugitive-style:
"
"   <CR> / o   show the change under the cursor (`jj show`) in a split
"   ~          reblame the file as of that change's parent
"   q          close the blame column
"
" Plain-git repos fall back to fugitive's `:Git blame`.

if exists('g:loaded_jj_blame') | finish | endif
let g:loaded_jj_blame = 1

" Columns shown per line; the change-id is the first whitespace-delimited token
" so we can recover it under the cursor without a parallel data structure.
let s:tmpl = 'pad_end(8, commit.change_id().shortest(8))'
      \ . ' ++ "  " ++ pad_end(13, truncate_end(13, commit.author().name()))'
      \ . ' ++ "  " ++ commit.author().timestamp().local().format("%Y-%m-%d")'
      \ . ' ++ "\n"'

function! s:err(msg) abort
  echohl ErrorMsg | echo 'blame: ' . a:msg | echohl None
endfunction

" --- column coloring (text properties) ---------------------------------------
" The id column gets a distinct color per change (cycled, so adjacent changes
" differ); author and date are greens that darken with the change's age. Syntax
" highlighting can't do either (it can't key off the value), so we compute it
" here and attach text properties to the generated buffer.
let s:change_colors = ['#fd971f', '#66d9ef', '#ae81ff', '#e6db74',
      \ '#f92672', '#fd8ec1', '#7aa6da', '#d6a05a']
let s:auth_green = ['#d7ff87', '#b6f24a', '#95d62e', '#6fae2e', '#4f7a26', '#3a5520']
let s:date_green = ['#9fc36a', '#86b73a', '#6f9a26', '#557d22', '#3f5d1e', '#2e4319']

function! s:daynum(y, m, d) abort
  let l:cum = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
  return a:y * 365 + l:cum[a:m - 1] + a:d
endfunction

" Age bucket (0 newest .. 5 oldest) from a YYYY-MM-DD string.
function! s:bucket(date) abort
  if a:date !~# '^\d\{4}-\d\d-\d\d$' | return len(s:auth_green) - 1 | endif
  let l:p = split(a:date, '-')
  let l:age = s:today - s:daynum(str2nr(l:p[0]), str2nr(l:p[1]), str2nr(l:p[2]))
  if l:age < 7   | return 0 | endif
  if l:age < 30  | return 1 | endif
  if l:age < 90  | return 2 | endif
  if l:age < 365 | return 3 | endif
  if l:age < 730 | return 4 | endif
  return 5
endfunction

" Define highlight groups + matching prop types once per session.
function! s:setup_colors() abort
  if get(s:, 'colors_done', 0) | return | endif
  let s:colors_done = 1
  let s:today = s:daynum(str2nr(strftime('%Y')), str2nr(strftime('%m')), str2nr(strftime('%d')))
  for [l:pfx, l:cols] in [['c', s:change_colors], ['auth', s:auth_green], ['date', s:date_green]]
    let l:i = 0
    for l:c in l:cols
      let l:grp = 'JjBlame_' . l:pfx . l:i
      execute 'highlight default ' . l:grp . ' guifg=' . l:c
      silent! call prop_type_delete('jjblame_' . l:pfx . l:i)
      call prop_type_add('jjblame_' . l:pfx . l:i, {'highlight': l:grp})
      let l:i += 1
    endfor
  endfor
endfunction

function! s:apply_colors(buf, lines) abort
  if !has('textprop') | return | endif
  call s:setup_colors()
  call prop_clear(1, max([1, len(a:lines)]), {'bufnr': a:buf})
  let l:seen = {}
  let l:next = 0
  let l:lnum = 1
  for l:line in a:lines
    let l:id = matchstr(l:line, '^\S\+')
    if !empty(l:id)
      if !has_key(l:seen, l:id)
        let l:seen[l:id] = l:next % len(s:change_colors)
        let l:next += 1
      endif
      call prop_add(l:lnum, 1, {'length': strlen(l:id),
            \ 'type': 'jjblame_c' . l:seen[l:id], 'bufnr': a:buf})
    endif
    let l:date = matchstr(l:line, '\d\{4}-\d\d-\d\d$')
    let l:astart = matchend(l:line, '^\S\+\s\+') + 1   " 1-based col where author starts
    let l:dstart = strlen(l:line) - 9                  " 1-based col of the 10-char date
    let l:b = s:bucket(l:date)
    if l:astart > 1 && l:dstart > l:astart
      call prop_add(l:lnum, l:astart, {'length': l:dstart - l:astart,
            \ 'type': 'jjblame_auth' . l:b, 'bufnr': a:buf})
      call prop_add(l:lnum, l:dstart, {'length': 10,
            \ 'type': 'jjblame_date' . l:b, 'bufnr': a:buf})
    endif
    let l:lnum += 1
  endfor
endfunction

" Run jj from `dir` so the right workspace resolves regardless of Vim's cwd.
function! s:jj(dir, args) abort
  return systemlist('cd ' . shellescape(a:dir) . ' && jj ' . a:args)
endfunction

function! s:in_jj(dir) abort
  call s:jj(a:dir, 'root --ignore-working-copy >/dev/null 2>&1')
  return !v:shell_error
endfunction

" Annotate `file` (in `dir`) at `rev`, returning the rendered column lines.
function! s:annotate(dir, file, rev) abort
  let l:r = empty(a:rev) ? '' : ('-r ' . shellescape(a:rev) . ' ')
  return s:jj(a:dir, 'file annotate --ignore-working-copy ' . l:r
        \ . '-T ' . shellescape(s:tmpl) . ' -- ' . shellescape(a:file))
endfunction

function! s:jj_blame() abort
  let l:dir  = expand('%:p:h')
  let l:file = expand('%:t')
  if empty(l:file) | call s:err('no file in this buffer') | return | endif
  let l:srcbuf  = bufnr('%')
  let l:srcline = line('.')

  let l:lines = s:annotate(l:dir, l:file, '')
  if v:shell_error | call s:err(join(l:lines, ' ')) | return | endif

  " Scroll/cursor binding needs the blame column to have exactly as many lines as
  " the source buffer; if a stale snapshot makes them disagree, the binding would
  " smear attribution against the wrong lines, so refuse rather than mislead.
  if len(l:lines) != line('$')
    call s:err('annotation is out of sync with the buffer (save the file?)')
    return
  endif

  " Remember the source window's view options so we can restore them on close.
  let l:save = {'scb': &l:scrollbind, 'crb': &l:cursorbind, 'wrap': &l:wrap}
  setlocal scrollbind cursorbind nowrap

  leftabove vnew
  let l:blamebuf = bufnr('%')
  call setline(1, l:lines)
  setlocal buftype=nofile bufhidden=wipe noswapfile nowrap nonumber norelativenumber
  setlocal nolist signcolumn=no scrollbind cursorbind cursorline winfixwidth
  execute 'vertical resize ' . (max(map(copy(l:lines), 'strdisplaywidth(v:val)')) + 1)
  setlocal filetype=jjblame
  call s:apply_colors(l:blamebuf, l:lines)
  setlocal nomodifiable

  let b:jj_blame_dir   = l:dir
  let b:jj_blame_file  = l:file
  let b:jj_blame_src   = l:srcbuf
  let b:jj_blame_save  = l:save
  let b:jj_blame_rev   = ''

  nnoremap <buffer> <silent> <CR> :call <SID>show()<CR>
  nnoremap <buffer> <silent> o    :call <SID>show()<CR>
  nnoremap <buffer> <silent> ~    :call <SID>reblame()<CR>
  nnoremap <buffer> <silent> q    :call <SID>close()<CR>

  " Land both windows on the line you were reading and lock the scroll together.
  execute 'normal! ' . l:srcline . 'Gzz'
  syncbind
endfunction

" change-id under the cursor in the blame column.
function! s:id_here() abort
  return matchstr(getline('.'), '^\S\+')
endfunction

" Show the change under the cursor in a scratch split.
function! s:show() abort
  let l:id = s:id_here()
  if empty(l:id) | return | endif
  let l:dir = b:jj_blame_dir
  let l:out = s:jj(l:dir, 'show --ignore-working-copy -r ' . shellescape(l:id))
  if v:shell_error | call s:err(join(l:out, ' ')) | return | endif
  keepalt botright split
  enew
  call setline(1, l:out)
  setlocal buftype=nofile bufhidden=wipe noswapfile nomodifiable
  setlocal filetype=git
  execute 'resize ' . min([len(l:out) + 1, 25])
  nnoremap <buffer> <silent> q :close<CR>
endfunction

" Reblame the file as of the parent of the change under the cursor.
function! s:reblame() abort
  let l:id = s:id_here()
  if empty(l:id) | return | endif
  let l:rev = l:id . '-'
  let l:lines = s:annotate(b:jj_blame_dir, b:jj_blame_file, l:rev)
  if v:shell_error | call s:err(join(l:lines, ' ')) | return | endif
  " The parent's content differs from the source, so detach from the binding and
  " keep the reblame standalone.
  call s:unbind_src()
  setlocal noscrollbind nocursorbind modifiable
  silent %delete _
  call setline(1, l:lines)
  call s:apply_colors(bufnr('%'), l:lines)
  setlocal nomodifiable
  let b:jj_blame_rev = l:rev
  echo 'blame @ ' . l:rev
endfunction

function! s:unbind_src() abort
  let l:src = get(b:, 'jj_blame_src', -1)
  let l:save = get(b:, 'jj_blame_save', {})
  if l:src < 0 || !bufexists(l:src) | return | endif
  let l:win = bufwinid(l:src)
  if l:win == -1 | return | endif
  call win_execute(l:win, 'setlocal '
        \ . (get(l:save, 'scb', 0)  ? 'scrollbind' : 'noscrollbind') . ' '
        \ . (get(l:save, 'crb', 0)  ? 'cursorbind' : 'nocursorbind') . ' '
        \ . (get(l:save, 'wrap', 1) ? 'wrap' : 'nowrap'))
endfunction

function! s:close() abort
  call s:unbind_src()
  close
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
