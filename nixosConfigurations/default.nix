{ nixpkgs, flake, flakeRoot, sops, wrappers }:
let
  inherit (nixpkgs) lib;
  mkConfig = config:
    lib.nixosSystem (config {
      specialArgs = {
        inherit flakeRoot;
        wlib = wrappers.lib;
        wrappers = flake.wrappers;
      };
      specialModules = [
        ({ pkgs, ... }: let
          system = pkgs.stdenv.hostPlatform.system;
        in {
          _module.args.flakePkgs = flake.packages.${system};
        })
        sops.nixosModules.sops
      ];
    });
  mkConfigs = configs:
    builtins.mapAttrs (_: mkConfig) (
      builtins.listToAttrs (
        lib.collect
          (x: x ? name && x ? value)
          (lib.mapAttrsRecursive (p: value: {
            name = lib.concatStringsSep "-" p;
            inherit value;
          }) configs)
      ));
in
mkConfigs {
  # this attrset is expected to respect paths
  workstations = import ./workstations;
}
