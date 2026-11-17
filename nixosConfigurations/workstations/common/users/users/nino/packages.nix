{ flakePkgs, pkgs, ... }: {
  users.users.nino.packages = (with flakePkgs; [
    neovide
  ]) ++ (with pkgs; [
    firefox
  ]);
}
