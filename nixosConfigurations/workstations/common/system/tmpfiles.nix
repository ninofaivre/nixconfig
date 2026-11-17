{ ... }: {
  users.groups = {
    nix-config = {};
  };
  systemd.tmpfiles.settings = {
    nixos-directories = {
      "/etc/nixos" = {
        Z = {
          user = "root";
          group = "root";
        };
        A = {
          argument = "g:nix-config:rwX,d:g:nix-config:rwX";
        };
      };
    };
  };
}
