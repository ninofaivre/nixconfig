{ config, ... }: {
  imports = [
    ./groups.nix
    ./users
  ];
}
