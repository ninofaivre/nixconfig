{ configPath }:
{ pkgs, ... }: {
  imports = [
    (import ../../common { inherit configPath; })
    ./system
    ./services
    ./programs
    ./users
    ./wrappers.nix
    ./locales.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true; # TODO
}
