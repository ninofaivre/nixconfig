# TODO doc : add examples to options
# TODO validateConfig / check
# TODO output.monitors (https://triadwm.org/configuration/monitors/) low priority as ill probably manage
# my monitors imperatively...
# TODO shells (https://triadwm.org/configuration/shell-setup/#the-shells-block) low priority, I won't use it
# TODO workspace-rules
# TODO input.devices
# TODO janet mid priority, will do it at some point when I want to use it
# note that everything should still be doable without having to edit this module, those TODOs are just
# nicer way to do things without having to dive too deep to generators.toKdl or to create derivations
({wlib, lib, pkgs, config, ...}@args: let
  singleValueAttrsOf = valueType: lib.types.addCheck (lib.types.attrsOf valueType) (v:
    builtins.length (builtins.attrNames v) == 1
  );
  attrsToListOfSingleValueAttrs = attr: lib.mapAttrsToList (n: v: { ${n} = v; }) attr;
  attrsToProps = attr: { props = attrsToListOfSingleValueAttrs attr; };
  firstLevelRepeat = with lib; {
    spawn-at-startup = {
      type = with types; coercedTo str toList (listOf str);
      description = ''
        Startup Commands
        See <https://triadwm.org/configuration/basics/#startup-commands>
      '';
    };
    window-rule = {
      type = types.submodule {
        freeformType = with types; attrsOf (oneOf [ bool int str ]);
        options = let
          type = with types; nullOr (attrsOf (oneOf [ bool str ]));
        in {
          match = mkOption {
            inherit type;
            default = null;
          };
          exclude = mkOption {
            inherit type;
            default = null;
          };
        };
      };
      description = ''
        Window Rules
        See <https://triadwm.org/configuration/window-rules>
      '';
      transform = v: 
        if (v.match == null && v.exclude == null) then
          throw "Every window-rule should contain either match or exlude"
        else
          filterAttrs (_: v: v != null) (v // {
            match = if v.match != null then _: attrsToProps v.match else null;
            exclude = if v.exclude != null then _: attrsToProps v.exclude else null;
          });
    };
    include = {
      type = with types; coercedTo str toList (listOf (either str (singleValueAttrsOf bool)));
      description = ''
        Modular Configuration
        See <https://triadwm.org/configuration/basics/#modular-configuration>
      '';
      transform = v: _: { props = v; };
    };
  };
in {

  # not using wlib.modules.default on purpose to avoid symlinkScript
  imports = with wlib.modules; [
    makeWrapper
    constructFiles
    systemd
  ];

  options = with lib; {
    check = mkOption {
      type = mkEnableOption "check config" // { default = true; };
    };
    river-package = mkOption {
      type = types.package;
      default = pkgs.river;
      description = ''
        The river package to use as triad backend, make sure its version is in sync with what's
        required by your triad version, otherwise be prepared for a nice crash at startup.
      '';
    };
    # TODO figure where to put this description because the package option declaration cannot be merged
    # package = mkOption {
    #   type = types.package;
    #   description = ''
    #     The triad package to use. As of 11/18/2026 triad is not in nixpkgs. You might want to
    #     get it from <https://github.com/dmkhitaryan/river-next-nix-module>, in which case you
    #     probably want to define the river-package as river-next from the same repo. Getting
    #     river from nixpkgs-unstable might also work depending on what river version is expected
    #     by triad.
    #     See <#river-package>.
    #   '';
    # };
    settings = mkOption {
      type = types.submodule {
        freeformType = wlib.types.attrsRecursive;
        options = {
          bindings =
          let
            type = with types; let
              el = either str (singleValueAttrsOf (oneOf [ bool int str ]));
            in attrsOf (coercedTo el toList (listOf el));
            bindings = {
              binds = mkOption {
                inherit type;
                default = {};
                description = ''
                  Keyboard Bindings
                  See <https://triadwm.org/configuration/key-bindings/#keyboard-bindings>
                '';
              };
              pointer-binds = mkOption {
                inherit type;
                default = {};
                description = ''
                  Pointer Bindings
                  See <https://triadwm.org/configuration/key-bindings/#pointer-bindings>
                '';
              };
              axis-binds = mkOption {
                inherit type;
                default = {};
                description = ''
                  Scroll Wheel Bindings
                  See <https://triadwm.org/configuration/key-bindings/#scroll-wheel-bindings>
                '';
              };
              gesture-binds = mkOption {
                inherit type;
                default = {};
                description = ''
                  Gesture Bindings
                  See <https://triadwm.org/configuration/key-bindings/#gesture-bindings>
                '';
              };
            };
          in
          {
            layouts = mkOption {
              type = with types; attrsOf (submodule {
                options = bindings;
              });
              default = {};
              description = ''
                Layout-Scoped Bindings
                See <https://triadwm.org/configuration/key-bindings/#layout-scoped-bindings>
              '';
            };
          } // bindings;
          # spawns-at-startup = mkOption {
          #   type = with types; listOf (coercedTo str toList (listOf str));
          #   default = [];
          #   description = ''
          #     Startup Commands
          #     See <https://triadwm.org/configuration/basics/#startup-commands>
          #   '';
          # };
        } // (mapAttrs' (optionName: optionValue: 
          nameValuePair ("${optionName}s") (mkOption {
            type = types.listOf optionValue.type;
            inherit (optionValue) description;
            default = [];
          })
        ) firstLevelRepeat);
      };
      default = {};
      description = ''
        This settings will be passed to </nix-wrapper-modules/lib/generators.html#function-library-wlib.generators.toKdl> with some syntactic sugars being processed beforehand.
      '';
    };
    extraSettings = mkOption {
      type = with types; listOf (attrsOf wlib.types.attrsRecursive);
      default = [];
      description = ''
        Extra settings that needs to go in your triad kdl config
        and needs to be repeated but are not included in <#settings>.
        Will be passed as is to </nix-wrapper-modules/lib/generators.html#function-library-wlib.generators.toKdl>.
      '';
    };
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        This string will be appended to the kdl generated config.
      '';
    };
  };

  config = {
    constructFiles = {
      config = {
        content =
        let
          mkBindings = bindings: builtins.concatLists (
            lib.mapAttrsToList (bindingsName: bindingValue:
              lib.mapAttrsToList (bind: action: {
                ${lib.removeSuffix "s" bindingsName} = _: { props = [ bind ] ++ action; };
              }) bindingValue
            ) bindings
          );
        in
        (wlib.generators.toKdl (builtins.concatLists [
          # bindings without layouts
          (lib.toList {
            bindings = mkBindings (lib.removeAttrs config.settings.bindings [ "layouts" ]);
          })
          # bindings.layouts
          (lib.toList {
            bindings = lib.mapAttrsToList (layoutName: layoutValue: {
              layout = _: {
                props = [ layoutName ];
                content = (mkBindings layoutValue);
              };
            }) config.settings.bindings.layouts;
          })
          # firstLevelRepeat
          (builtins.concatLists (lib.mapAttrsToList (optionName: optionValue: map (v: {
            ${optionName} = if optionValue?transform then optionValue.transform v else v;
          }) (config.settings."${optionName}s")) firstLevelRepeat))
          # freeform without our defined options
          (lib.toList (lib.removeAttrs config.settings ([
            "bindings"
          ] ++ (map (v: "${v}s") (builtins.attrNames firstLevelRepeat)))))
          config.extraSettings
        ]))
        + "\n"
        + config.extraConfig;
        relPath = ".config/${config.binName}/config.kdl";
      };

      session = {
        content = /*bash*/ ''
          #!${lib.getExe pkgs.bash}
          export TRIAD_RIVER_BIN=${lib.getExe config.river-package}
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

      desktopEntry =
      let
        displayName = lib.toSentenceCase config.binName;
      in
      {
        content = lib.generators.toINI {} (lib.setAttrByPath ["Desktop Entry"] {
          Name = "River (${displayName})";
          Exec = config.constructFiles.session.path;
          Comment = "River Wayland compositor with the ${displayName} window manager";
          Type = "Application";
          DesktopNames = "river";
        });
        relPath = "share/wayland-sessions/${config.binName}.desktop";
      };
    };

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

    passthru.providedSessions = [ config.binName ];
    install.modules.nixos = { config, ... }:
    let
      cfg = args.config.install.getWrapperConfig config;
    in
    {
      services.displayManager.sessionPackages = [ cfg.wrapper ];
    };
    # buildCommands.configCheck = lib.mkIf config.check /*bash*/ ''
    #   ${lib.getExe config.package} validate-config --config=${config.constructFiles.config.path}
    # '';
    appendFlag = [{
      data = ''$([[ ( $# -eq 1 && "$1" == "validate-config" ) || $# -eq 0 ]] && echo "--config=${config.constructFiles.config.path}")'';
      esc-fn = s: ''"${s}"'';
    }];
  };
})
