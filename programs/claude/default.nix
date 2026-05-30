{pkgs, ...}: {
  imports = [./sandbox.nix];

  programs.claude-code = {
    enable = true;

    memory.source = ./CLAUDE.md;

    commandsDir = ./commands;

    settings = {
      autoMemoryEnabled = true;
      autoDreamEnabled = true;
      skipDangerousModePermissionPrompt = true;
      hooks.PreToolUse = [
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
