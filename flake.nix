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
          ]).overrideAttrs (_: { meta.mainProgram = "neovide"; });
          neovide-ssh = pkgs.writeShellApplication {
            name = "neovide-ssh";
            runtimeInputs = with pkgs; [
              self'.packages.neovide
              fuzzel
            ];
            text = ''
              case $# in
                0) 
                  hosts=$(awk '$1 == "Host" {
                      for (i=2; i<=NF; i++) {
                          if ($i !~ /[\*?]/) print $i
                      }
                  }' ~/.ssh/config)
                  host=$(echo "$hosts" | fuzzel --dmenu --prompt="SSH Host : ")
                  [ -z "$host" ] && exit 0
                ;;
                1) host="$1";;
                *) exit 1;;
              esac

              socketName="$(echo "$host" | sha256sum | cut -d' ' -f1)"
              socketPath="/tmp/''${socketName}"

              rm -f "$socketPath"
              ssh -L "$socketPath:$socketPath" "$host" "
                rm -f $socketPath
                if command -v nix >/dev/null; then
                  nix run github:ninofaivre/nixconfig#neovim -- --headless --listen $socketPath
                else
                  # TODO use nixie there instead of nix-portable which is out of date and looks unmaintained
                  return
                  # if [ ! -x /tmp/nix-portable ]; then
                  #   curl -sL https://github.com/DavHau/nix-portable/releases/latest/download/nix-portable-x86_64 -o /tmp/nix-portable
                  #   chmod +x /tmp/nix-portable
                  # fi
                  # /tmp/nix-portable nix run github:ninofaivre/nixconfig#neovim -- --headless --listen $socketPath
                fi
              " &
              sleep 3; neovide --server="$socketPath"
            '';
          };
        };

        apps = {
          neovide = {
            type = "app";
            program = lib.getExe (gl self'.packages.neovide);
          };
          neovide-ssh = {
            type = "app";
            program = lib.getExe (gl self'.packages.neovide-ssh);
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
                (gl self'.packages.neovide-ssh)
                self'.packages.neovim
              ];
            })
          ];
        });
    });
}
