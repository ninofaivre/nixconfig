{ specialArgs, specialModules }:
{
  inherit specialArgs;
  modules = [
    ./hardware-configuration.nix
    (import ../common { configPath = ./.; })
    ./config.nix
  ] ++ specialModules;
}
