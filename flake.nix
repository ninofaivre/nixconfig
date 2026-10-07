{
  description = "Home Manager configuration of nino";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wrappers = {
      url = "github:nix-community/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixgl.url = "github:nix-community/nixGL";

    neovim.url = ./wrapped/neovim;
  };

  outputs = {
    self,
    nixpkgs, home-manager, wrappers, flake-parts,
    nixgl,
    neovim, 
    ...
    }@inputs: flake-parts.lib.mkFlake { inherit inputs; } ({ config, withSystem, lib, ... }: let
      systemsMap = lib.genAttrs config.systems (s: s);
    in {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        wrappers.flakeModules.wrappers
        home-manager.flakeModules.home-manager
      ];

      flake.wrappers = {
        neovim = neovim.lib.nvimModule;
      };

      perSystem = { self', system, pkgs, lib, ... }:
      with (import ./utils.nix { inherit pkgs lib; }); {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [ nixgl.overlay ];
        };

        wrappers.packages.neovim = true;
        packages.neovim = self.wrappers.neovim.wrap {
          pkgs = neovim.lib.mkPkgs system;
        };

        packages = {
          neovide = (pkgs.linkFarm "neovide" [
            {
              name = "bin/neovide";
              path = lib.getExe' self'.packages.neovim "nvim-neovide";
            }
            {
              name = "share";
              path = "${pkgs.neovide}/share";
            }
          ]).overrideAttrs (_: {
              meta.mainProgram = "neovide";
            });
        };
        apps = {
          neovide = {
            type = "app";
            program = lib.getExe (gl self'.packages.neovide);
          };
        };
      };

      flake.homeConfigurations."nino@ninoArchLinuxDesktop" = withSystem systemsMap.x86_64-linux
        ({ self', pkgs, ... }: home-manager.lib.homeManagerConfiguration {
          inherit pkgs;

          modules = [
            ./home-manager/home.nix
            ({ config, ... }: {
              targets.genericLinux.nixGL.packages = nixgl.packages;
              home.packages = let
                gl = config.lib.nixGL.wrap;
              in [
                (gl self'.packages.neovide)
                self'.packages.neovim
              ];
            })
          ];
        });
    });
}
