{...}: {
  programs.claude-code = {
    enable = true;

    memory.source = ./CLAUDE.md;

    commandsDir = ./commands;

    settings = {
      enabledPlugins = {
        "infracost@infracost" = true;
        "gopls-lsp@claude-plugins-official" = true;
      };
      permissions.allow = [
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
        "Write(**/.claude/context.md)"
        "Write(**/.claude/session)"
        "Write(**/.claude/pid)"
        "Write(**/.claude/subagent-prompts/**)"
        "Bash(fish -c 'spawn-subagent*')"
      ];
    };
  };
}
