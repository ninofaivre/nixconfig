{ lib, flakePkgs, ... }: {
  environment.variables = {
    EDITOR = lib.getExe flakePkgs.neovim;
  };
}
