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

      # `jj log` with no args. We use per-branch sibling workspaces, so the
      # question we actually want answered is "where do my worktrees sit
      # relative to trunk?" — not "dump all mutable history + N commits of
      # trunk", which the old revset did and which always overflowed the pager.
      #
      #   fork_point(working_copies() | trunk()) :: (working_copies() | trunk())
      #
      # - working_copies(): the `@` of every workspace (each worktree), including
      #   ones based on an older commit than trunk (which `trunk()::@` would drop).
      # - trunk(): the default branch tip.
      # - fork_point(...):(...): the DAG range from their common fork point up to
      #   each tip, so jj draws the branch lines connecting every worktree to
      #   trunk. Shows only the commits needed to relate them — typically a
      #   handful, no pager. (Pathological orphan branches with no recent common
      #   ancestor could widen this; in practice worktrees sit near trunk.)
      revsets.log = "fork_point(working_copies() | trunk())::(working_copies() | trunk())";

      # `jj log` shows the author's email by default, override the alias to show the
      # author's name instead if set.
      template-aliases."format_short_signature(signature)" = "if(signature.name(), signature.name(), signature.email())";

      # Auto-reconcile a workspace whose working copy went stale because another
      # workspace rewrote a commit it depends on (rebase/amend/squash). jj's
      # default is false, which would force a manual `jj workspace update-stale`;
      # we use per-branch sibling workspaces (Model B), so enable it for seamless
      # restacks across them.
      snapshot.auto-update-stale = true;

      # Auto-track new bookmarks on the origin remote so `jj git push`
      # automatically creates them.
      remotes.origin.auto-track-bookmarks = "glob:*";

      ui = {
        default-command = "log";
        editor = "vim";
        merge-editor = "mergiraf";
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
