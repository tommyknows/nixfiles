# Jujutsu (jj) config. Colocated with git — git config in ../git stays the
# source of truth for identity/signing, and this mirrors it so jj behaves the
# same. See jj-migration-map.html for the broader plan.
{config, ...}: {
  programs.jujutsu = {
    enable = true;
    settings = {
      # Reuse git's personal identity so the two never drift.
      user = {
        name = config.programs.git.settings.user.name;
        email = config.programs.git.settings.user.email;
      };

      # SSH commit signing via the same Secretive key git uses. `signing.key`
      # is host-specific (set in hosts/<host>/user.nix for git); we reuse it.
      signing = {
        behavior = "own";
        backend = "ssh";
        key = config.programs.git.signing.key;
      };

      # `jj log` with no args. The built-in default
      #   present(@) | ancestors(immutable_heads().., 2) | present(trunk())
      # shows your mutable stack + trunk but nothing *below* trunk, so history
      # stops at the trunk merge commit. Extend it: deeper mutable stacks
      # (depth 5, so long stacks show fully) plus ~10 commits of trunk history.
      # Tune the two depths to taste.
      revsets.log = "present(@) | ancestors(immutable_heads().., 5) | present(trunk()) | ancestors(trunk(), 10)";

      # Auto-reconcile a workspace whose working copy went stale because another
      # workspace rewrote a commit it depends on (rebase/amend/squash). jj's
      # default is false, which would force a manual `jj workspace update-stale`;
      # we use per-branch sibling workspaces (Model B), so enable it for seamless
      # restacks across them.
      snapshot.auto-update-stale = true;

      ui = {
        default-command = "log";
        # Explicit so jj's editor (change descriptions, `jj describe`, split, etc.)
        # never depends on whether $EDITOR happens to be exported. Mirrors $EDITOR.
        editor = "vim";

        # Default tool for `jj resolve` (despite the name, not a UI — it's jj's
        # generic term for the conflict-resolution program, like `diff-editor`).
        # mergiraf is non-interactive: it syntax-merges what it can and leaves the
        # rest as conflicts (its default merge-tools config exits 1 → jj keeps
        # them). jj ships the mergiraf merge-tools args; this just makes plain
        # `jj resolve` use it without `--tool mergiraf`. (mergiraf is in packages.)
        merge-editor = "mergiraf";
        # Render diffs through delta (git-format diffs piped to delta). delta
        # picks up its [delta] options from gitconfig (programs.delta), so the
        # look matches git verbatim, and it does word-level intra-line + syntax
        # highlighting.
        #
        # TODO: evaluate difftastic instead — syntax-aware structural/word diff,
        # closer to jj's native color-words feel. Would be:
        #   ui.diff-formatter = ["difft" "--color=always" "$left" "$right"];
        # (add `difftastic` to packages; no pager needed for it).
        pager = "delta";
        diff-formatter = ":git";
      };
    };
  };
}
