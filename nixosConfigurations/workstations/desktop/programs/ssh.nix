{ config, ... }: {
  sops.secrets.sshKey = {};
  programs.ssh = {
    extraConfig = ''
      Math user root
        IdentityFile ${config.sops.secrets.sshKey.path}
    '';
  };
}
