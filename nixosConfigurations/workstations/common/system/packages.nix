{ pkgs, flakePkgs, ... }: {
  environment.systemPackages = (with pkgs; [
    age
  ]) ++ (with flakePkgs; [
    neovim
  ]);
}
