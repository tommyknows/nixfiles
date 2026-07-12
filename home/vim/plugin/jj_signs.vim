" jj-native gutter signs.
"
" gitgutter/coc-git show the current diff in the sign column, but they shell out
" to git and need a .git in the working dir — which a non-colocated jj workspace
" doesn't have. This is the jj analogue: it diffs the buffer against the file's
" content at `@-` (the parent of the working-copy commit), i.e. *the current
" change*, and places add/change/delete signs.
"
" It reads jj's live state on every refresh, so there is nothing to keep in
" sync: `jj new`/rebase/squash just move `@-`, and the next refresh picks it up.
" The expensive part (fetching the base file) is cached by the `@-` commit id and
" only refetched when `@-` actually moves; recomputing signs as you type is pure
" Vim (diff()), no jj call.
"
" Only active inside a jj repo; in a plain-git repo it stays out of the way and
" lets coc-git/gitgutter handle the gutter.

if exists('g:loaded_jj_signs') | finish | endif
let g:loaded_jj_signs = 1

" Needs the sign API and the native line-differ (Vim 9.1.0099+).
if !has('signs') || !exists('*sign_place') || !exists('*diff')
  finish
endif

let g:jj_signs_base     = get(g:, 'jj_signs_base', '@-')
let g:jj_signs_debounce = get(g:, 'jj_signs_debounce', 200)

" Default highlights (material-monokai palette); `default` so a colorscheme or
" the user can override. termguicolors is on, ctermfg given as a fallback.
highlight default JjSignsAdd          guifg=#a6e22e ctermfg=148
highlight default JjSignsChange       guifg=#e6db74 ctermfg=185
highlight default JjSignsDelete       guifg=#f92672 ctermfg=197
highlight default link JjSignsChangeDelete JjSignsChange

" Glyphs default to coc-git's (see coc-settings.json) so jj and git workspaces
" look the same: a thin left bar for add/change/delete, an upper bar for
" deletions at the top of the file. Color (green/yellow/red) tells them apart.
" Override any subset via g:jj_signs_text in the vimrc.
let s:text = extend({'add': '▎', 'change': '▎', 'delete': '▎',
      \ 'topdelete': '▔', 'changedelete': '▎'}, get(g:, 'jj_signs_text', {}))
call sign_define('jjsigns_add',          {'text': s:text.add,          'texthl': 'JjSignsAdd'})
call sign_define('jjsigns_change',       {'text': s:text.change,       'texthl': 'JjSignsChange'})
call sign_define('jjsigns_delete',       {'text': s:text.delete,       'texthl': 'JjSignsDelete'})
call sign_define('jjsigns_topdelete',    {'text': s:text.topdelete,    'texthl': 'JjSignsDelete'})
call sign_define('jjsigns_changedelete', {'text': s:text.changedelete, 'texthl': 'JjSignsChangeDelete'})

" Run a jj command from `dir` (so the right workspace is resolved regardless of
" Vim's cwd). Returns the output lines; sets v:shell_error on failure.
function! s:jj(dir, args) abort
  return systemlist('cd ' . shellescape(a:dir) . ' && jj ' . a:args)
endfunction

function! s:Clear(bufnr) abort
  call sign_unplace('jjsigns', {'buffer': a:bufnr})
  call setbufvar(a:bufnr, 'jj_signs_hunks', [])
endfunction

" Is this a buffer we should decorate? Real, named, file-backed buffers only.
function! s:Eligible() abort
  return &buftype ==# '' && !empty(bufname('%')) && filereadable(expand('%:p'))
endfunction

" Cached per buffer: -1 unknown, 0 not a jj repo, 1 jj repo.
function! s:InJj(dir) abort
  if exists('b:jj_signs_active') && b:jj_signs_active >= 0
    return b:jj_signs_active
  endif
  call s:jj(a:dir, 'root --ignore-working-copy >/dev/null 2>&1')
  let b:jj_signs_active = v:shell_error ? 0 : 1
  return b:jj_signs_active
endfunction

" Commit id of the diff base (default `@-`), or '' if it can't be resolved
" (e.g. `@` is on top of root with no parent).
function! s:BaseRev(dir) abort
  let l:out = s:jj(a:dir, 'log --no-graph --ignore-working-copy -r '
        \ . shellescape(g:jj_signs_base) . ' -T commit_id 2>/dev/null')
  return v:shell_error ? '' : get(l:out, 0, '')
endfunction

" File content at the base rev, as a list of lines. Empty list if the file does
" not exist there (a newly added file → everything shows as added).
function! s:FetchBase(dir, file) abort
  let l:out = s:jj(a:dir, 'file show --ignore-working-copy -r '
        \ . shellescape(g:jj_signs_base) . ' -- ' . shellescape(a:file) . ' 2>/dev/null')
  return v:shell_error ? [] : l:out
endfunction

" Recompute hunks from the cached base vs the live buffer and place signs.
" Pure Vim — no jj call — so it's cheap enough to run on every keystroke.
function! s:Update(bufnr) abort
  if bufnr('%') != a:bufnr || !exists('b:jj_signs_baselines') | return | endif
  let l:cur = getline(1, '$')
  let l:hunks = diff(b:jj_signs_baselines, l:cur, {'output': 'indices'})
  let l:signs = []
  let l:ranges = []
  for h in l:hunks
    let l:fc = h.from_count
    let l:tc = h.to_count
    let l:tstart = h.to_idx + 1            " 1-based first new line of the hunk
    if l:fc == 0 && l:tc > 0
      " pure addition
      for l in range(l:tstart, l:tstart + l:tc - 1)
        call add(l:signs, s:sign(a:bufnr, l, 'jjsigns_add'))
      endfor
      call add(l:ranges, [l:tstart, l:tstart + l:tc - 1])
    elseif l:tc == 0 && l:fc > 0
      " pure deletion: mark the surviving line the gap sits under (top → line 1)
      let l:lnum = h.to_idx == 0 ? 1 : h.to_idx
      let l:name = h.to_idx == 0 ? 'jjsigns_topdelete' : 'jjsigns_delete'
      call add(l:signs, s:sign(a:bufnr, l:lnum, l:name))
      call add(l:ranges, [l:lnum, l:lnum])
    else
      " change; if more lines were removed than added, flag the last as change+delete
      for l in range(l:tstart, l:tstart + l:tc - 1)
        let l:name = (l:fc > l:tc && l == l:tstart + l:tc - 1)
              \ ? 'jjsigns_changedelete' : 'jjsigns_change'
        call add(l:signs, s:sign(a:bufnr, l, l:name))
      endfor
      call add(l:ranges, [l:tstart, l:tstart + l:tc - 1])
    endif
  endfor
  call sign_unplace('jjsigns', {'buffer': a:bufnr})
  if !empty(l:signs) | call sign_placelist(l:signs) | endif
  call setbufvar(a:bufnr, 'jj_signs_hunks', l:ranges)
endfunction

function! s:sign(bufnr, lnum, name) abort
  return {'buffer': a:bufnr, 'group': 'jjsigns', 'name': a:name,
        \ 'lnum': a:lnum, 'priority': 10}
endfunction

" Full refresh: detect jj, resolve the base rev, refetch the base file if it
" moved (or forced), then redraw signs.
function! s:Refresh(force) abort
  if !s:Eligible() | return | endif
  let l:bufnr = bufnr('%')
  let l:dir = expand('%:p:h')
  if !s:InJj(l:dir)
    call s:Clear(l:bufnr)
    return
  endif
  let l:rev = s:BaseRev(l:dir)
  if empty(l:rev)
    call s:Clear(l:bufnr)
    return
  endif
  if a:force || !exists('b:jj_signs_baseid') || b:jj_signs_baseid !=# l:rev
        \ || !exists('b:jj_signs_baselines')
    let b:jj_signs_baselines = s:FetchBase(l:dir, expand('%:t'))
    let b:jj_signs_baseid = l:rev
  endif
  call s:Update(l:bufnr)
endfunction

" Debounced text-change handler: only recompute signs (cheap), don't re-hit jj.
let s:timer = -1
function! s:Schedule() abort
  if !exists('b:jj_signs_active') || b:jj_signs_active != 1 | return | endif
  let l:bufnr = bufnr('%')
  if s:timer != -1 | call timer_stop(s:timer) | endif
  let s:timer = timer_start(g:jj_signs_debounce, {-> s:Update(l:bufnr)})
endfunction

" Jump to the next/prev hunk (wraps).
function! s:Hunk(dir) abort
  let l:hunks = get(b:, 'jj_signs_hunks', [])
  if empty(l:hunks) | return | endif
  let l:cur = line('.')
  let l:starts = map(copy(l:hunks), 'v:val[0]')
  call sort(l:starts, 'n')
  if a:dir > 0
    for s in l:starts
      if s > l:cur | call cursor(s, 1) | return | endif
    endfor
    call cursor(l:starts[0], 1)
  else
    for s in reverse(copy(l:starts))
      if s < l:cur | call cursor(s, 1) | return | endif
    endfor
    call cursor(l:starts[-1], 1)
  endif
endfunction

" Popup showing the base→working diff for the hunk under the cursor.
function! s:HunkPreview() abort
  if get(b:, 'jj_signs_active', 0) != 1 || !exists('b:jj_signs_baselines')
    echohl WarningMsg | echo 'jj-signs: no hunk data here' | echohl None
    return
  endif
  let l:cur = getline(1, '$')
  let l:diff = diff(b:jj_signs_baselines, l:cur)
  if empty(l:diff)
    echo 'jj-signs: no changes vs ' . g:jj_signs_base | return
  endif
  let l:lines = split(l:diff, "\n")
  let l:line = line('.')
  " Find the hunk header covering the cursor; show that hunk's body.
  let l:start = -1 | let l:end = len(l:lines)
  let l:idx = 0
  for ln in l:lines
    if ln =~# '^@@'
      let l:m = matchlist(ln, '+\(\d\+\)\%(,\(\d\+\)\)\?')
      if !empty(l:m)
        let l:s = str2nr(l:m[1])
        let l:c = empty(l:m[2]) ? 1 : str2nr(l:m[2])
        if l:line >= l:s && l:line <= l:s + l:c - 1
          let l:start = l:idx | break
        endif
      endif
    endif
    let l:idx += 1
  endfor
  if l:start == -1 | let l:start = 0 | endif
  " Body runs until the next @@ header.
  let l:body = [l:lines[l:start]]
  let l:j = l:start + 1
  while l:j < len(l:lines) && l:lines[l:j] !~# '^@@'
    call add(l:body, l:lines[l:j]) | let l:j += 1
  endwhile
  call popup_atcursor(l:body, {'border': [], 'padding': [0,1,0,1],
        \ 'moved': 'any', 'highlight': 'Normal', 'title': ' @- diff '})
endfunction

" :HunkInfo dispatches like :Blame — jj preview in a jj repo, coc-git otherwise.
function! s:HunkInfo() abort
  if get(b:, 'jj_signs_active', 0) == 1
    call s:HunkPreview()
  else
    silent! CocCommand git.chunkInfo
  endif
endfunction

command! JjSignsRefresh call <SID>Refresh(1)
command! JjHunkPreview  call <SID>HunkPreview()
command! HunkInfo       call <SID>HunkInfo()

nnoremap <silent> ]h :call <SID>Hunk(1)<CR>
nnoremap <silent> [h :call <SID>Hunk(-1)<CR>

augroup jj_signs
  autocmd!
  autocmd BufReadPost,BufEnter,FocusGained,BufWritePost,ShellCmdPost * call <SID>Refresh(0)
  autocmd TextChanged,TextChangedI,InsertLeave * call <SID>Schedule()
  autocmd ColorScheme * call <SID>Redefine()
augroup END

" Re-assert default highlights after a colorscheme swap.
function! s:Redefine() abort
  highlight default JjSignsAdd    guifg=#a6e22e ctermfg=148
  highlight default JjSignsChange guifg=#e6db74 ctermfg=185
  highlight default JjSignsDelete guifg=#f92672 ctermfg=197
  highlight default link JjSignsChangeDelete JjSignsChange
endfunction
