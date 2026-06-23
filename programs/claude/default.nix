{pkgs, ...}: let
  # Stamp the active session id onto the current tmux pane so title.sh
  # and vim's claude-ask plugin can resolve titles per pane. Fires on
  # every SessionStart event (including /resume), which is the only way
  # to learn the id when cl wasn't told `--resume` at launch.
  tmuxMarkerHook = pkgs.writeShellScript "claude-tmux-marker" ''
    [ -n "''${TMUX_PANE:-}" ] || exit 0
    session_id=$(${pkgs.jq}/bin/jq -r '.session_id // .sessionId // empty' 2>/dev/null || true)
    [ -n "$session_id" ] || exit 0
    ${pkgs.tmux}/bin/tmux set-option -p -t "$TMUX_PANE" @claude-id "$session_id" 2>/dev/null || true
  '';

  # Custom `@`-mention file search — replaces the built-in, which roots its
  # search via `git rev-parse` and so breaks in jj non-colocated workspaces.
  # Full rationale + the `@:` cross-tree syntax live in file-suggestion.sh;
  # writeShellApplication adds the shebang/`set` and puts rg/jq/fzf on PATH.
  fileSuggestionScript = pkgs.writeShellApplication {
    name = "claude-file-suggestion";
    runtimeInputs = [pkgs.ripgrep pkgs.jq pkgs.fzf pkgs.coreutils];
    text = builtins.readFile ./file-suggestion.sh;
  };
in {
  imports = [./sandbox.nix];

  programs.claude-code = {
    enable = true;

    context = ./CLAUDE.md;

    commandsDir = ./commands;

    # MCP servers are wrapped onto the claude binary via --mcp-config; the
    # server definition is declarative, OAuth tokens are stored at runtime
    # (via /mcp) in the credentials store, not here.
    mcpServers = {
      linear-server = {
        type = "http";
        url = "https://mcp.linear.app/mcp";
      };
    };

    settings = {
      autoMemoryEnabled = true;
      autoDreamEnabled = true;
      skipDangerousModePermissionPrompt = true;
      fileSuggestion = {
        type = "command";
        command = "${fileSuggestionScript}/bin/claude-file-suggestion";
      };
      hooks = {
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                # PATH-based rather than ${pkgs.unstable.rtk}/bin/rtk so rtk's own
                # "is hook installed" check (which compares the literal string)
                # recognizes the hook. rtk is in home.packages, so always on PATH.
                command = "rtk hook claude";
              }
            ];
          }
        ];
        SessionStart = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${tmuxMarkerHook}";
              }
            ];
          }
        ];
      };
      enabledPlugins = {
        "infracost@infracost" = true;
        "gopls-lsp@claude-plugins-official" = true;
      };
      permissions = {
        allow = [
          "Edit(***)"
          "Bash(go build*)"
          "Bash(go test*)"
          "Bash(go get*)"
          "Bash(go run*)"
          "Bash(go mod*)"
          "Bash(go vet*)"
          "Bash(go fmt*)"
          "Bash(go generate*)"
          "Bash(go install*)"
          "Bash(gofmt*)"
          "Bash(git diff*)"
          "Bash(git log*)"
          # jj equivalents of the read-only git allowances above (repos are
          # migrating to jj; these are the commands run constantly while reading).
          "Bash(jj log*)"
          "Bash(jj st*)"
          "Bash(jj diff*)"
          "Bash(jj show*)"
          "Bash(jj op log*)"
          "Read(**/.claude/skills/**)"
          "Write(**/.claude/context.md)"
          "Write(**/.claude/session)"
          "Write(**/.claude/subagent-prompts/**)"
          "Bash(fish -c 'prepare-subagent*')"
        ];
      };
    };
  };
}
