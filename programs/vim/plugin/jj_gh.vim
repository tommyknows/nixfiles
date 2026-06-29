" jj-aware GitHub line URLs (:GH blob, :GB blame).
"
" vim-gh-line shells out to git to build the URL. In a non-colocated jj
" workspace that misfires: the workspace has no .git of its own, but git still
" discovers the *bare* store at the repo root, so `git remote` / `git config` /
" `git rev-parse HEAD` succeed while `git rev-parse --show-toplevel` fails (it's
" a bare repo). vim-gh-line then computes the repo-relative path as
" split(fullPath, gitRoot)[-1] with an empty gitRoot, so it glues the file's
" absolute path onto the URL:
"
"   github.com/OWNER/REPO/blob/<sha>/Users/ramon/Documents/work/.../file.go#L419
"
" These commands dispatch: in a jj repo the URL is built from jj (remote, a
" pushed commit, and the workspace root); otherwise we hand off to vim-gh-line
" unchanged so plain-git repos keep all of its host support and range handling.
"
" The URL is emitted via g:gh_open_command (the user routes it to pbcopy), the
" same channel vim-gh-line uses, and echoed for feedback.

if exists('g:loaded_jj_gh') | finish | endif
let g:loaded_jj_gh = 1

function! s:err(msg) abort
  echohl ErrorMsg | echo 'gh: ' . a:msg | echohl None
endfunction

" Run from `dir` so the right workspace/repo resolves regardless of Vim's cwd.
function! s:jj(dir, args) abort
  return systemlist('cd ' . shellescape(a:dir) . ' && jj ' . a:args)
endfunction

function! s:git(dir, args) abort
  return systemlist('cd ' . shellescape(a:dir) . ' && git ' . a:args)
endfunction

function! s:in_jj(dir) abort
  call system('cd ' . shellescape(a:dir) . ' && jj root --ignore-working-copy >/dev/null 2>&1')
  return !v:shell_error
endfunction

function! s:is_github(remote) abort
  return a:remote =~# 'github'
endfunction

" A git remote (ssh or https) -> its https web base, without the .git suffix.
"   git@github.com:o/r.git       -> https://github.com/o/r
"   ssh://git@github.com/o/r.git -> https://github.com/o/r
"   https://github.com/o/r.git   -> https://github.com/o/r
function! s:web_base(remote) abort
  let l:u = substitute(a:remote, '\.git$', '', '')
  let l:u = substitute(l:u, '^\w\+://', '', '')   " strip scheme (https://, ssh://)
  let l:u = substitute(l:u, '^[^@/]*@', '', '')   " strip user@ (before any path)
  let l:u = substitute(l:u, ':', '/', '')         " scp-style host:path -> host/path
  return 'https://' . l:u
endfunction

function! s:line_range(l1, l2) abort
  return a:l1 == a:l2 ? 'L' . a:l1 : 'L' . a:l1 . '-L' . a:l2
endfunction

function! s:rel_path(root, full) abort
  return substitute(a:full, '^' . escape(a:root, '\.^$~[]') . '/', '', '')
endfunction

" jj git remote url: prefer origin, else the first remote.
function! s:jj_remote(dir) abort
  let l:lines = s:jj(a:dir, 'git remote list')
  if v:shell_error | return '' | endif
  let l:pick = ''
  for l:l in l:lines
    let l:url = matchstr(l:l, '^\S\+\s\+\zs\S\+')
    if empty(l:url) | continue | endif
    if l:l =~# '^origin\s' | return l:url | endif
    if empty(l:pick) | let l:pick = l:url | endif
  endfor
  return l:pick
endfunction

" A commit that actually resolves on the remote: the closest pushed ancestor of
" the working copy, else trunk, else @ itself (unpushed, but faithful).
function! s:jj_commit(dir) abort
  for l:rev in ['latest(::@ & remote_bookmarks())', 'trunk()', '@']
    let l:out = s:jj(a:dir, 'log -r ' . shellescape(l:rev)
          \ . ' --no-graph --ignore-working-copy -T ' . shellescape('commit_id'))
    if !v:shell_error && !empty(l:out) && l:out[0] =~# '^[0-9a-f]\{40}$'
      return l:out[0]
    endif
  endfor
  return ''
endfunction

function! s:emit(url) abort
  echo a:url
  let l:cmd = get(g:, 'gh_open_command', '')
  if !empty(l:cmd)
    call system(l:cmd . shellescape(a:url))
  endif
endfunction

function! s:gh(action) range abort
  let l:dir  = expand('%:p:h')
  let l:full = expand('%:p')
  if empty(l:full) | call s:err('no file in this buffer') | return | endif

  if s:in_jj(l:dir)
    let l:remote = s:jj_remote(l:dir)
    let l:commit = s:jj_commit(l:dir)
    let l:root   = get(s:jj(l:dir, 'root --ignore-working-copy'), 0, '')
  else
    let l:remote = get(s:git(l:dir, 'config --get remote.origin.url'), 0, '')
    let l:commit = get(s:git(l:dir, 'rev-parse HEAD'), 0, '')
    let l:root   = get(s:git(l:dir, 'rev-parse --show-toplevel'), 0, '')
  endif

  if empty(l:remote) | call s:err('no git remote') | return | endif

  " Non-GitHub remote: in a plain-git repo defer to vim-gh-line (all its hosts;
  " only multi-line range is lost, since its <Plug> map is single-line). In a
  " jj repo we have no such fallback, so say so rather than emit a bad URL.
  if !s:is_github(l:remote)
    if s:in_jj(l:dir)
      call s:err('only github remotes are supported in jj workspaces (got ' . l:remote . ')')
    else
      execute 'normal ' . (a:action ==# 'blame' ? "\<Plug>(gh-line-blame)" : "\<Plug>(gh-line)")
    endif
    return
  endif

  if empty(l:commit) || empty(l:root)
    call s:err('could not resolve commit/root') | return
  endif

  let l:act = a:action ==# 'blame' ? '/blame/' : '/blob/'
  call s:emit(s:web_base(l:remote) . l:act . l:commit . '/'
        \ . s:rel_path(l:root, l:full) . '#' . s:line_range(a:firstline, a:lastline))
endfunction

" vim-gh-line defines :GH/:GB; defining ours from VimEnter guarantees we win the
" override regardless of plugin load order.
function! s:setup() abort
  command! -range GH <line1>,<line2>call <SID>gh('blob')
  command! -range GB <line1>,<line2>call <SID>gh('blame')
  " Blame-URL map, jj-aware (replaces vim-gh-line's <leader>gB -> broken in jj).
  nnoremap <silent> <leader>gB :GB<CR>
  xnoremap <silent> <leader>gB :GB<CR>
endfunction

augroup jj_gh
  autocmd!
  autocmd VimEnter * call s:setup()
augroup END
