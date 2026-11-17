{ hostName, ... }: {
  environment.shellAliases = {
    rebuild = /*bash*/ "sudo nixos-rebuild --flake /etc/nixos#${hostName}";
  };
}
