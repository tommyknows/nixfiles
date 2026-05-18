{
  pkgs,
  config,
  internal-skills,
  ...
}: let
  codeDir = "${config.home.homeDirectory}/Documents/work";
  skills = pkgs.runCommandLocal "infracost-skills" {} ''
    cp -r ${internal-skills}/.claude/skills $out
    chmod -R u+w $out
    find $out -type f -name '*.md' -exec sed -i "s|{{CODE_DIR}}|${codeDir}|g" {} +
  '';
in {
  home.file.".claude/skills" = {
    source = skills;
    recursive = true;
  };
}
