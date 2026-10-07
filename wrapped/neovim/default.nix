{ extraVimPluginsInputs, ... }:
{ wlib, config, lib, pkgs, ... }:
{
  imports = [ wlib.wrapperModules.neovim ];

  hosts.neovide.nvim-host = {
    enable = true;
  };

  env = {
    GI_TYPELIB_PATH = "${lib.getLib pkgs.glib}/lib/girepository-1.0/"; # system-theme
  };

  runtimePkgs = with pkgs; [
  ];
  runtimeLibs = with pkgs; [
  ];

  settings = {
    config_directory = ./lua;
    dont_link = true;
    block_normal_config = true;
    compile_generated_lua = true;

    buildEnv.packages = true;

    nvim_lua_env = lp: with lp; with pkgs.luajitPackages; [
      dbus_proxy # system-theme
    ];
  };

  specs = import ./specs {
    inherit pkgs lib;
    inherit (config) nvim-lib;
    extraVimPlugins = (lib.mapAttrs config.nvim-lib.mkPlugin extraVimPluginsInputs);
  };
}
