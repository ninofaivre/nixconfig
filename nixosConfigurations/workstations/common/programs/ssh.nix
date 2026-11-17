{ config, ... }: {
  users.groups.ssh = {
    members = map (u: u.name) (with config.users.users; [
      root
      nino
    ]);
  };
  sops.secrets.sshKey = {
    group = config.users.groups.ssh.name;
    mode = "0440";
  };
  programs.ssh = {
    extraConfig = with config.users; ''
      Match localuser ${builtins.concatStringsSep "," groups.ssh.members}
        IdentityFile ${config.sops.secrets.sshKey.path}
        IdentitiesOnly yes
    '';
  };
}
