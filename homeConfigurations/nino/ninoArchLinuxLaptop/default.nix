{ pkgs, home-manager, ... }: extraSpecialArgs:
home-manager.lib.homeManagerConfiguration {
  inherit pkgs extraSpecialArgs;
  modules = [ (./. + "/../*") ];
}
