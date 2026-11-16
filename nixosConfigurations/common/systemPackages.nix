{ hostName, pkgs, wlib, ... }: {
  environment.systemPackages = [
    (wlib.evalPackage [
      { inherit pkgs; }
      ({ ... }: {
        imports = [ wlib.modules.default ];
        package = pkgs.sops;
        flags."--config" = "/etc/nixos/secrets/.sops.yaml";
        envDefault.SOPS_AGE_KEY_FILE="/root/sops-age-key_${hostName}.txt";
      })
    ])
  ];
}
