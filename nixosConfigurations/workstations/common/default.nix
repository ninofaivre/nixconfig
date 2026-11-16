{ configPath }:
{ lib, flakePkgs, pkgs, ... }: {
  imports = [ (import ../../common { inherit configPath; }) ];

  environment.systemPackages = (with pkgs; [
    age
  ]) ++ (with flakePkgs; [
    git
    neovim
  ]);
  environment.variables = {
    EDITOR = lib.getExe flakePkgs.neovim;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true; # TODO

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
   font = "Lat2-Terminus16";
   keyMap = "fr";
  };
}
