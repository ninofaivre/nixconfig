{ config, lib, flakeRoot, ... }: {
  imports = [
    ./packages.nix
  ];
  
  sops.secrets."users/nino" = {
    sopsFile = lib.path.append flakeRoot "secrets/workstations/common/secrets.yaml";
    neededForUsers = true;
  };
  users.users.nino = with config.users; {
    isNormalUser = true;
    createHome = true;
    group = groups.users.name;
    extraGroups = map (g: g.name) (with groups; [
      wheel
      nix-config
    ]);
    hashedPasswordFile = config.sops.secrets."users/nino".path;
    description = "6e696e6f private user";
  };
}
