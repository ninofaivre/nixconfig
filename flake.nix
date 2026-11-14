{
  description = "Home Manager configuration of nino";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
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
    catppuccin-fuzzel = { url = "github:catppuccin/fuzzel"; flake = false; };
    river-next-module = { url = "github:dmkhitaryan/river-next-nix-module"; flake = false; };
  };

  outputs = {
    self,
    nixpkgs, nixpkgs-unstable, home-manager, wrappers, flake-parts,
    nixgl,
    neovim, 
    catppuccin-fuzzel,
    river-next-module,
    ...
  }@inputs: flake-parts.lib.mkFlake { inherit inputs; } ({ config, withSystem, lib, ... }: let
    systemsMap = lib.genAttrs config.systems (s: s);
    catppuccin = rec {
      light = { flavor = "latte"; accent = "sapphire"; };
      dark = { flavor = "frappe"; accent = "sapphire"; };
      default = light;
    };
  in {
    systems = nixpkgs.lib.systems.flakeExposed;
    imports = [
      wrappers.flakeModules.wrappers
      home-manager.flakeModules.home-manager
    ];

    flake.wrappers = {
      neovim = neovim.lib.nvimModule { inherit catppuccin; };
      fuzzel = import ./wrapped/fuzzel.nix {
        inherit catppuccin-fuzzel catppuccin;
      };
      triad = { config, pkgs, ... }: let
        flakePkgs = { inherit (self.packages.${pkgs.stdenv.system}) fuzzel; };
      in {
        imports = [
          ({wlib, lib, pkgs, config, ...}: {

            /* not using wlib.modules.default on purpose to avoid symlinkScript
               as we do not want anything else than the binary */
            imports = with wlib.modules; [
              makeWrapper
              constructFiles
              systemd
            ];

            options = with lib; {
              check = mkOption {
                type = mkEnableOption "check config" // { default = true; };
              };
              conf = mkOption {
                type = with types; either attrs (listOf attrs);
                default = {};
                description = "Config to be converted to kdl.";
              };
            };

            config = let
              displayName = lib.toSentenceCase config.binName;
              unstablePkgs = import nixpkgs-unstable { system = "x86_64-linux"; }; # TODO ugly af
            in {
              constructFiles = {
                triadConf = let
                  conf = with lib; concatMap (el: let
                    spawnAtStartup = el?spawn-at-startup && (typeOf (head el.spawn-at-startup) == "list");
                  in
                    [(
                      (if spawnAtStartup then (removeAttrs el ["spawn-at-startup"]) else el)
                      // (optionalAttrs (el?bindings && (typeOf el.bindings == "set")) {
                        bindings = concatLists (mapAttrsToList (actionName: actionValues:
                          map (actionValue: { ${actionName} = actionValue; })
                            (if (typeOf actionValues == "set")
                            then (mapAttrsToList (name: value: [name] ++ (toList value)) actionValues)
                            else actionValues)
                        ) el.bindings);
                      })
                    )]
                    ++ (optionals spawnAtStartup (map (spawnEl: {
                      spawn-at-startup = spawnEl;
                    }) el.spawn-at-startup))
                  ) (toList config.conf);
                in {
                  content = wlib.generators.toKdl conf;
                  relPath = ".config/${config.binName}/config.kdl";
                };
                river-triad-session = {
                  content = /*bash*/ ''
                    #!${lib.getExe pkgs.bash}
                    export TRIAD_RIVER_BIN=${lib.getExe unstablePkgs.river}
                    if [[ "$(${lib.getExe' pkgs.coreutils "realpath"} "$(command -v ${config.binName})" 2>/dev/null)" == "${config.wrapperPaths.placeholder}" ]]; then
                      export TRIAD_BIN="${config.binName}"
                    else
                      export TRIAD_BIN="${config.wrapperPaths.placeholder}"
                      echo "WARNING: In order for triad-reload to use your latest wrapped triad, you need to add it to home.packages because triad session rely on the PATH to get it." >&2
                    fi
                    exec "$TRIAD_BIN" session
                  '';
                  relPath = "share/${config.binName}/tools/river-${config.binName}-session";
                  builder = ''cp "$1" "$2" && chmod +x "$2"'';
                };
                triadDesktopEntry = {
                  content = lib.generators.toINI {} (lib.setAttrByPath ["Desktop Entry"] {
                    Name = "River (${displayName})";
                    Exec = config.constructFiles.river-triad-session.path;
                    Comment = "River Wayland compositor with the ${displayName} window manager";
                    Type = "Application";
                    DesktopNames = "river";
                  });
                  relPath = "share/wayland-sessions/${config.binName}.desktop";
                };
              };

              # TODO will work only on nixos not home-manager because X-Restart-Triggers is unsupported on home-manager...
              systemd.user.service."${config.binName}-reload" = {
                Install.WantedBy = [ "default.target" ];
                Service = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  ExecStart = "-${config.wrapperPaths.placeholder} msg triad-reload";
                };
                Unit = {
                  Description = "Reload triad when derivation is rebuilt.";
                  X-Restart-Triggers = [ (placeholder "out") ];
                };
              };
              # TODO will work only on nixos not home-manager because X-Restart-Triggers is unsupported on home-manager...

              package = lib.mkDefault (unstablePkgs.callPackage (import river-next-module).packages.triad {}); # TODO ugly af
              # buildCommands.configCheck = lib.mkIf config.check /*bash*/ ''
              #   ${lib.getExe config.package} validate-config --config=${config.constructFiles.triadConf.path}
              # '';
              # TODO try again when stdout branch gets merged to main
              appendFlag = [{
                data = ''$([[ ( $# -eq 1 && "$1" == "validate-config" ) || $# -eq 0 ]] && echo "--config=${config.constructFiles.triadConf.path}")'';
                esc-fn = s: ''"${s}"'';
              }];
            };
          })
        ];

        runtimePkgs = with flakePkgs; [ fuzzel ];
        conf = {
          allow-exit-session = true;

          input.keyboard.xkb = {
            layout = "fr";
            variant = "";
            options = "terminate:ctrl_alt_bksp";
          };

          layout = {
            gaps = 16;
            center-focused-column = "on-overflow";
            default-column-width = { proportion = 0.5; };
            default-window-width = { proportion = 0.5; };
            default-window-height = { proportion = 1.0; };
            master = {
              count = 1;
              split-ratio = 0.55;
            };
            enable-animations = true;
            smart-gaps = true;
          };

          workspaces = {
            default-count = 4;
            default-layout = "tile";
          };

          bindings.bind = {
            "Super+q" = "spawn kitty";
            "Super+d" = "spawn fuzzel";
            "Super+c" = "close-window";
            "Super+m" = "spawn ${config.wrapperPaths.placeholder} msg exit-session";
            "Super+x" = "spawn ${config.wrapperPaths.placeholder} msg triad-reload";
          

            "Super+h" = "focus-left";
            "Super+l" = "focus-right";
            "Super+k" = "focus-up";
            "Super+j" = "focus-down";

            "Super+Shift+h" = "move-column-left";
            "Super+Shift+l" = "move-column-right";
            "Super+Shift+k" = "move-window-up";
            "Super+Shift+j" = "move-window-down";


            "Super+a" = "focus-workspace 1";
            "Super+z" = "focus-workspace 2";
            "Super+e" = "focus-workspace 3";
            "Super+r" = "focus-workspace 4";

            "Super+Shift+a" = "move-to-workspace 1";
            "Super+Shift+z" = "move-to-workspace 2";
            "Super+Shift+e" = "move-to-workspace 3";
            "Super+Shift+r" = "move-to-workspace 4";
          };
          spawn-at-startup = [
            [ "touch" "/tmp/testoa" ]
          ];
        };
      };
    };

    perSystem = { self', system, pkgs, lib, ... }:
    with (import ./utils.nix { inherit pkgs lib; }); {
      _module.args.pkgs = import nixpkgs {
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
      };
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
