{ flakePkgs, river-next-module }:
{ wlib, pkgs, ... }: {
  imports = [ (import ../wrappers/triad.nix) ];

  package = pkgs.callPackage river-next-module.packages.triad {};
  river-package = pkgs.callPackage river-next-module.packages.river-next {};

  runtimePkgs = (with flakePkgs; [
    fuzzel
    ghostty
  ]) ++ (with pkgs; [
    wl-clipboard-rs
  ]);

  settings = {
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

    bindings.binds = {
      "Super+q" = "spawn ghostty";
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
    spawns-at-startup = [
      [ "touch" "/tmp/jkljlkklj" ]
    ];
  };
}
