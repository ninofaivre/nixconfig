{ specialArgs, specialModules }:
{
  inherit specialArgs;
  modules = [
    (import ../common { configPath = ./.; })
  ] ++ specialModules;
}
