{internal-skills, ...}: {
  home.file.".claude/skills" = {
    source = "${internal-skills}/.claude/skills";
    recursive = true;
  };
}
