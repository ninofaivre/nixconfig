{ configPath }:
{ pkgs, lib, wlib, ... }: let
  hostPath = lib.path.removePrefix ./.. configPath;
  hostName = lib.concatStringsSep "-" (lib.path.subpath.components hostPath);
in {
  _module.args = { inherit hostName hostPath; };

  imports = [
    ./sops.nix
    ./shellAliases.nix
    ./systemPackages.nix
  ];

  networking.hostName = "nixos-nino-${hostName}";
}
