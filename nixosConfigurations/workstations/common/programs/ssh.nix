{ config, ... }: {
  sops.secrets.sshKey = {};
  programs.ssh = {
    extraConfig = ''
      Match localuser root
        IdentityFile ${config.sops.secrets.sshKey.path}
        IdentitiesOnly yes
    '';
  };
}
