{ config, lib, flakePkgs, ... }: {
  environment.variables = {
    EDITOR = lib.getExe flakePkgs.neovim;
    VISUAL = lib.getExe flakePkgs.neovide;
  };
  security.sudo.extraConfig = ''
    Defaults env_keep += "EDITOR VISUAL"
  '';
}
