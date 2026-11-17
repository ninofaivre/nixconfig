{ hostName, ... }: {
  environment.shellAliases = {
    rebuild = /*bash*/ "nixos-rebuild --flake /etc/nixos#${hostName} -S";
  };
}
