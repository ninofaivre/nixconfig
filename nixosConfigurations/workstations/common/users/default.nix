{ ... }: {
  imports = [
    ./groups.nix
    ./users
  ];
  users.mutableUsers = false;
}
