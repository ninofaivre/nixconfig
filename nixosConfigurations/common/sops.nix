{ hostPath, hostName, lib, ... }: {
  sops = {
    defaultSopsFile = lib.path.append ../../secrets (lib.path.subpath.join [
      (lib.removePrefix "./" hostPath)
      "secrets.yaml"
    ]);
    age.keyFile = "/root/sops-age-key_${hostName}.txt";
  };
}
