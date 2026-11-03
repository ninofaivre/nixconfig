{ flake, config, unstablePkgs, pkgs, nixgl, river-next-module, ... }: let
  triad = unstablePkgs.callPackage
    (import river-next-module).packages.triad
    {};
  riztile = unstablePkgs.callPackage
    (import river-next-module).packages.riztile
    {};
in {
  imports = [ ./home.nix ];

  targets.genericLinux.nixGL.packages = nixgl.packages;
  news.display = "silent";

  home.packages = let
    gl = config.lib.nixGL.wrap;
  in with pkgs; with flake.packages; [
    (gl neovide)
    (gl fuzzel)
    neovim
    triad
    (gl unstablePkgs.river)
  ];
}
