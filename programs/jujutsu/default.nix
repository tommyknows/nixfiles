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

      # `jj log` shows the author's email by default, override the alias to show the
      # author's name instead if set.
      template-aliases."format_short_signature(signature)" = "if(signature.name(), signature.name(), signature.email())";

      aliases = {
        # print the description of the revision, defaulting to `@`.
        # `show` insists on appending a diff, so `--tool true` swaps in a no-op diff
        # command that emits nothing, leaving only the `-T description` output.
        msg = ["show" "-T" "description" "--tool" "true"];
      };

      # Auto-reconcile a workspace whose working copy went stale because another
      # workspace rewrote a commit it depends on (rebase/amend/squash). jj's
      # default is false, which would force a manual `jj workspace update-stale`;
      # we use per-branch sibling workspaces (Model B), so enable it for seamless
      # restacks across them.
      snapshot.auto-update-stale = true;

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
