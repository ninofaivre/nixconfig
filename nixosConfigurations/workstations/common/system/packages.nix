{ pkgs, flakePkgs, ... }: {
  environment.systemPackages = (with pkgs; [
    age
  ]) ++ (with flakePkgs; [
    git
    neovim
  ]);
}
