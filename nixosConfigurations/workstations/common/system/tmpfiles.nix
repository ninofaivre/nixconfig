{ config, ... }: {
  users.groups = {
    nix-config = {};
  };
  systemd.tmpfiles.settings = {
    nixos-directories = {
      "/etc/nixos" = with config.users; {
        Z = {
          user = users.root.name;
          group = groups.root.name;
        };
        A = {
          argument = "g:${groups.nix-config.name}:rwX,d:g:${groups.nix-config.name}:rwX";
        };
      };
    };
  };
}
