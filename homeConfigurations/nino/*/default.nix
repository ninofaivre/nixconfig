{ flake, flake', config, unstablePkgs, pkgs, nixgl, ... }: {
  imports = [
    ./home.nix
    flake.wrappers.triad.install
  ];

  wrappers.triad.enable = true;

  targets.genericLinux.nixGL.packages = nixgl.packages;
  news.display = "silent";

  home.packages = let
    gl = config.lib.nixGL.wrap;
  in with pkgs; with flake'.packages; [
    (gl neovide)
    # fuzzel
    neovim
    # triad
    # (gl unstablePkgs.river)
  ];
}
