{ catppuccin-fuzzel, catppuccin }:
{ wlib, pkgs, ... }: {
  imports = [ wlib.wrapperModules.fuzzel ];
  settings = {
    main = {
      include = "~/.local/state/fuzzel/theme.ini";
      auto-select = "yes";
    };
  };
  runtimePkgs = with pkgs; [ coreutils util-linux glib ];
  runShell = [ /*bash*/ ''
    case "$(gsettings get org.gnome.desktop.interface color-scheme)" in
      "'prefer-dark'")
        flavor=${catppuccin.dark.flavor}
        accent=${catppuccin.dark.accent}
      ;;
      "'prefer-light'")
        flavor=${catppuccin.light.flavor}
        accent=${catppuccin.light.accent}
      ;;
      "'default'")
        flavor=${catppuccin.default.flavor}
        accent=${catppuccin.default.accent}
      ;;
      *)
        echo "unknown gnome desktop color-scheme" >&2
        flavor=${catppuccin.default.flavor}
        accent=${catppuccin.default.accent}
      ;;
    esac

    mkdir -p ~/.local/state/fuzzel
    ln -sf "${catppuccin-fuzzel}/themes/catppuccin-$flavor/$accent.ini" ~/.local/state/fuzzel/theme.ini
  '' ];
}
