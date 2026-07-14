" Ask the current worktree's claude session about specific lines.
" Finds the tmux pane marked by `cl` for this worktree (@claude-session
" pane option), pastes a prompt with the selected text + your question,
" and focuses the pane. If no marked pane exists, spawns a fresh session
" in a new tmux window running `cl . <prompt>`.

if exists('g:loaded_claude_ask') | finish | endif
let g:loaded_claude_ask = 1

function! s:err(msg) abort
  echohl ErrorMsg | echo 'claude-ask: ' . a:msg | echohl None
endfunction

" Worktree/workspace root — the dir `cl` records in @claude-session. In a jj
" repo this is the jj workspace root: jj workspaces are non-colocated (no .git),
" so `git rev-parse` fails there. Try jj first (--ignore-working-copy so merely
" locating the root never triggers a snapshot), then fall back to the git
" worktree toplevel for plain-git repos.
function! s:worktree_root() abort
  let l:r = systemlist('jj root --ignore-working-copy 2>/dev/null')
  if !v:shell_error && !empty(l:r) | return l:r[0] | endif
  let l:r = systemlist('git rev-parse --show-toplevel 2>/dev/null')
  if !v:shell_error && !empty(l:r) | return l:r[0] | endif
  return ''
endfunction

function! s:project_dir(cwd) abort
  return expand('~/.claude/projects/') . substitute(a:cwd, '/', '-', 'g')
endfunction

" Picker label for a session. Prefers a custom-title (user `/rename`),
" then ai-title (auto-generated; what /resume shows). Falls back to the
" first user-typed message if neither has been written yet.
function! s:session_summary(jsonl_path) abort
  let l:custom = ''
  let l:ai = ''
  let l:first_user = ''
  for l:line in readfile(a:jsonl_path, '', 200)
    if empty(l:line) | continue | endif
    try
      let l:obj = json_decode(l:line)
    catch
      continue
    endtry
    if type(l:obj) != v:t_dict | continue | endif
    let l:t = get(l:obj, 'type', '')
    if l:t ==# 'custom-title'
      let l:custom = get(l:obj, 'customTitle', '')
      break
    endif
    if l:t ==# 'ai-title'
      let l:ai = get(l:obj, 'aiTitle', '')
      continue
    endif
    if empty(l:first_user) && l:t ==# 'user'
      let l:msg = get(l:obj, 'message', {})
      if type(l:msg) == v:t_dict
        let l:c = get(l:msg, 'content', '')
        if type(l:c) == v:t_string && !empty(l:c) | let l:first_user = l:c | endif
      endif
    endif
  endfor
  if !empty(l:custom) | return l:custom | endif
  if !empty(l:ai) | return l:ai | endif
  return l:first_user
endfunction

function! s:rel(path, wt) abort
  let l:prefix = a:wt . '/'
  if strpart(a:path, 0, len(l:prefix)) ==# l:prefix
    return strpart(a:path, len(l:prefix))
  endif
  return a:path
endfunction

function! s:build_prompt(file_rel, l1, l2, sel, q) abort
  let l:ref = a:l1 == a:l2 ? printf('%s:%d', a:file_rel, a:l1)
        \ : printf('%s:%d-%d', a:file_rel, a:l1, a:l2)
  return printf("Re %s:\n```\n%s\n```\n\n%s", l:ref, a:sel, a:q)
endfunction

" Match on @claude-session == worktree. pane_current_command is
" unreliable (shows the deepest descendant — often bash when claude is
" mid-tool-call), so we trust the marker instead. `cl` clears it on
" return, so the only stale case is SIGKILL.
"
" The label must distinguish split panes in a single window — window_name
" is identical across them. So we build it from the session title (resolved
" from @claude-id like title.sh does) plus the window.pane location and an
" active marker, all of which are pane-unique. The fields in l:fmt are
" delimiter-safe (pane id, a path, a uuid, integers) — the human-readable
" title is resolved in vim, never passed through the '|'-split.
function! s:find_panes(worktree) abort
  let l:fmt = join([
        \ '#{pane_id}',
        \ '#{@claude-session}',
        \ '#{@claude-id}',
        \ '#{window_index}',
        \ '#{pane_index}',
        \ '#{?pane_active,*,}',
        \ ], '|')
  let l:out = systemlist('tmux list-panes -sF ' . shellescape(l:fmt))
  if v:shell_error | return [] | endif
  let l:hits = []
  for l:line in l:out
    let l:p = split(l:line, '|', 1)
    if len(l:p) < 6 | continue | endif
    if l:p[1] !=# a:worktree | continue | endif
    let l:id = l:p[2]
    let l:loc = printf('%s.%s', l:p[3], l:p[4])
    let l:active = l:p[5] ==# '*' ? ' *' : ''
    let l:summary = ''
    if !empty(l:id)
      let l:jsonl = s:project_dir(l:p[1]) . '/' . l:id . '.jsonl'
      if filereadable(l:jsonl)
        let l:summary = substitute(s:session_summary(l:jsonl), '\n.*', '', '')
      endif
    endif
    if empty(l:summary) | let l:summary = empty(l:id) ? '(starting…)' : '(untitled)' | endif
    if strlen(l:summary) > 60 | let l:summary = l:summary[:57] . '...' | endif
    call add(l:hits, {'id': l:p[0], 'label': printf('[%s%s] %s', l:loc, l:active, l:summary)})
  endfor
  return l:hits
endfunction


function! s:inject(pane_id, prompt) abort
  call system('tmux load-buffer -', a:prompt)
  if v:shell_error | call s:err('tmux load-buffer failed') | return | endif
  call system('tmux paste-buffer -p -d -t ' . shellescape(a:pane_id))
  if v:shell_error | call s:err('tmux paste-buffer failed') | return | endif
  " Deliberately no `send-keys Enter` — the prompt is left unsubmitted in the
  " input box so you can edit it (multi-line formatting) or paste several asks
  " from different lines before hitting Enter yourself.
  " Focus the pane within the current session: raise its window
  " (cross-window — select-pane alone won't), then select the pane. We
  " never switch tmux sessions — claude panes in other sessions are
  " deliberately invisible to claude-ask (list-panes -s is session-scoped).
  call system('tmux select-window -t ' . shellescape(a:pane_id) . ' 2>/dev/null')
  call system('tmux select-pane -t ' . shellescape(a:pane_id))
endfunction

" Numbered `inputlist()` prompt. Returns the 1-based index of the chosen
" label, or 0 if cancelled / out of range.
function! s:numbered_pick(header, labels) abort
  let l:items = [a:header]
  let l:i = 1
  for l:label in a:labels
    call add(l:items, printf('%d. %s', l:i, l:label))
    let l:i += 1
  endfor
  let l:n = inputlist(l:items)
  if l:n < 1 || l:n > len(a:labels) | return 0 | endif
  return l:n
endfunction

" No existing claude session in this tmux session — spawn a fresh one in a
" new tmux window (which becomes active). Persistent main sessions should
" still be launched manually via `cl` in a regular pane; the plugin
" discovers them by marker and injects. Resuming sessions from disk was
" dropped deliberately: those are repo-wide (the project dir is symlinked
" across worktrees) and not scoped to this tmux session — re-add behind a
" separate mapping if that's ever wanted.
function! s:spawn(worktree, prompt) abort
  let l:cmd = 'cl . ' . shellescape(a:prompt)
  call system('tmux new-window -c ' . shellescape(a:worktree) . ' ' . shellescape(l:cmd))
endfunction

function! s:pick(hits) abort
  let l:labels = map(copy(a:hits), 'v:val.label')
  let l:n = s:numbered_pick('Multiple claude sessions, pick one:', l:labels)
  return l:n == 0 ? {} : a:hits[l:n - 1]
endfunction

function! s:ask(l1, l2) abort
  if empty($TMUX) | call s:err('not in tmux') | return | endif

  let l:wt = s:worktree_root()
  if empty(l:wt) | call s:err('not in a repo') | return | endif

  let l:abs = expand('%:p')
  if empty(l:abs) | call s:err('no file in this buffer') | return | endif
  let l:file_rel = s:rel(l:abs, l:wt)
  let l:sel = join(getline(a:l1, a:l2), "\n")

  let l:q = input('claude-ask> ')
  if empty(l:q) | redraw | echo 'claude-ask: cancelled' | return | endif

  let l:prompt = s:build_prompt(l:file_rel, a:l1, a:l2, l:sel, l:q)
  let l:hits = s:find_panes(l:wt)

  if len(l:hits) == 0
    call s:spawn(l:wt, l:prompt)
  elseif len(l:hits) == 1
    call s:inject(l:hits[0].id, l:prompt)
  else
    let l:chosen = s:pick(l:hits)
    if !empty(l:chosen) | call s:inject(l:chosen.id, l:prompt) | endif
  endif
endfunction

command! -range ClaudeAsk call <SID>ask(<line1>, <line2>)
nnoremap <silent> <Plug>(ClaudeAsk) :ClaudeAsk<CR>
xnoremap <silent> <Plug>(ClaudeAsk) :ClaudeAsk<CR>
