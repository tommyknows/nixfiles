{pkgs, ...}: {
  users.users.ramon = {
    createHome = true;
    home = "/Users/ramon";
    shell = pkgs.fish;
  };
}
