{ ... }: {
  users.groups = {
    nix-config = {};
  };
  systemd.tmpfiles.settings = {
    nixos-directories = {
      "/etc/nixos".A = {
        user = "root";
        group = "root";
        argument = "g:nix-config:rwX,d:g:nix-config:rwX";
      };
    };
  };
}
