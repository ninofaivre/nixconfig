{ hostName, ... }: {
  environment.shellAliases = {
    rebuild = /*bash*/ ''
      nixos-rebuild --flake /etc/nixos#${hostName} $(if [ "$USER" != "root" ]; then echo "--ask-sudo-password"; fi)'';
  };
}
