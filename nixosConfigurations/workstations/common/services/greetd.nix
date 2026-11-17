{ config, pkgs, lib, ... }: {
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings = {
      terminal.vt = 1;
      default_session.command = let
        share = "${config.services.displayManager.sessionData.desktops}/share";
      in "${lib.getExe pkgs.tuigreet} --time --remember --remember-session --greeting 'Bienvenue 6e696e6f' --background doom -s ${share}/wayland-sessions -x ${share}/xsessions";
    };
  };
}
