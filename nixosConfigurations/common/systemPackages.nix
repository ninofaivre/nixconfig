{ hostName, pkgs, wlib, ... }: {
  environment.systemPackages = [
    (wlib.evalPackage [
      { inherit pkgs; }
      ({ ... }: {
        imports = [ wlib.modules.default ];
        package = pkgs.sops;
        chdir = [ "/etc/nixos/secrets" ]; # --config and absolute secret path not needed thx to it
        envDefault.SOPS_AGE_KEY_FILE="/root/sops-age-key_${hostName}.txt";
      })
    ])
  ];
}
