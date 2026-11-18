{
  description = "Home Manager configuration of nino";

  inputs = {
    nixpkgs-nixos-unstable.url = "nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";

    wrappers = {
      url = "github:nix-community/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager.url = "github:nix-community/home-manager/release-26.05";

    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-nixos-unstable";
    };
    nixgl.url = "github:nix-community/nixGL";

    neovim.url = ./wrapped/neovim;
    catppuccin-fuzzel = { url = "github:catppuccin/fuzzel"; flake = false; };
    river-next-module = { url = "github:dmkhitaryan/river-next-nix-module"; flake = false; };
  };

  outputs = {
    self,
    nixpkgs-nixos-unstable, nixpkgs-unstable,
    wrappers, flake-parts,
    home-manager,
    sops, nixgl,
    neovim, catppuccin-fuzzel, river-next-module,
    ...
  }@inputs: flake-parts.lib.mkFlake { inherit inputs; } ({ config, withSystem, lib, ... }: let
    systemsMap = lib.genAttrs config.systems (s: s);
    catppuccin = rec {
      light = { flavor = "latte"; accent = "sapphire"; };
      dark = { flavor = "frappe"; accent = "sapphire"; };
      default = dark;
    };
  in {
    systems = nixpkgs-unstable.lib.systems.flakeExposed;
    imports = [
      wrappers.flakeModules.wrappers
      home-manager.flakeModules.home-manager
    ];

    flake.wrappers = {
      ghostty = import ./wrapped/ghostty.nix;
      neovim = neovim.lib.nvimModule { inherit catppuccin; };
      fuzzel = import ./wrapped/fuzzel.nix {
        inherit catppuccin-fuzzel catppuccin;
      };
      git = import ./wrapped/git.nix;
      triad = import ./wrapped/triad.nix {
        flakePkgs = system: { inherit (self.packages.${system}) fuzzel ghostty; };
        river-next-module = import river-next-module;
      };
    };

    perSystem = { self', system, pkgs, lib, ... }:
    with (import ./utils.nix { inherit pkgs lib; }); {
      _module.args.pkgs = import nixpkgs-unstable {
        inherit system;
        overlays = [ nixgl.overlay ];
      };

      wrappers.packages.neovim = true; # exclude neovim from auto packages so it can have custom pkgs
      packages.neovim = self.wrappers.neovim.wrap {
        pkgs = neovim.lib.mkPkgs system;
      };

      packages.quick-settings = let
        brightness-menu = pkgs.writeShellApplication {
          name = "brightness-menu";
          runtimeInputs = [ self'.packages.fuzzel pkgs.brightnessctl ];
          text = ''
            brightness=$(brightnessctl get)
            selection=$(printf "+\n-" | fuzzel -p "current_brightness $brightness >" -d "$@")
            case "$selection" in
              "") exit 0;;
              "+") brightnessctl set $(( brightness + 1000 ));;
              "-") brightnessctl set $(( brightness - 1000 ));;
              *) echo "unknown brightness value" >&2
            esac
            exec "$0" "$@" --select="$selection"
          '';
        };
      in pkgs.writeShellApplication {
        name = "quick-settings";
        runtimeInputs = with pkgs; [
          self'.packages.fuzzel
          glib dconf.lib # gsettings
          brightness-menu
        ];
        runtimeEnv = {
          GIO_EXTRA_MODULES = "${pkgs.dconf.lib}/lib/gio/modules";
        };
        text = /*bash*/ ''
          case "$(gsettings get org.gnome.desktop.interface color-scheme)" in
            "'prefer-dark'") theme="dark";;
            "'prefer-light'") theme="light";;
            "'default'") theme="light";; # TODO get default from catppuccin
            *) echo "unknown gnome desktop color-scheme" >&2;;
          esac
          menu=""
          menu=$(cat <<-EOF
            Toggle $theme theme|theme
            brightness|brightness
          EOF
          )
          selection=$(echo "$menu" | fuzzel -p "Quick-Settings >" -d --nth-delimiter='|' --with-nth=1 --accept-nth=2)
          case "$selection" in
            "") exit 0;;
            "theme")
              case "$theme" in
                "light") theme="dark";;
                "dark") theme="light";;
              esac
              gsettings set org.gnome.desktop.interface color-scheme "prefer-$theme"
            ;;
            "brightness") brightness-menu;;
          esac
          exec "$0" "$@"
        '';
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
      };
      apps = {
        neovide = {
          type = "app";
          program = lib.getExe (gl self'.packages.neovide);
        };
        triad = {
          type = "app";
          program = "${self'.packages.triad}/share/triad/tools/river-triad-session";
        };
      };
    };

    flake.nixosConfigurations = (import ./nixosConfigurations) {
      inherit sops wrappers;
      nixpkgs = nixpkgs-nixos-unstable;
      flake = self;
      flakeRoot = ./.;
    };

    flake.homeConfigurations = withSystem systemsMap.x86_64-linux ({ self', pkgs, system, ... }:
      import ./homeConfigurations { inherit pkgs lib home-manager; } {
        inherit nixgl river-next-module;
        flake' = self';
        flake = self;
        unstablePkgs = import nixpkgs-unstable { inherit system; };
      }
    );
  });
}
