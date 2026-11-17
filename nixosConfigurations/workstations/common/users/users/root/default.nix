{ config, lib, flakeRoot, ... }: {
  sops.secrets."users/root" = {
    sopsFile = lib.path.append flakeRoot "secrets/workstations/common/secrets.yaml";
    neededForUsers = true;
  };
  users.users.root = with config.users; {
    createHome = true;
    group = groups.root.name;
    hashedPasswordFile = config.sops.secrets."users/root".path;
  };
}
