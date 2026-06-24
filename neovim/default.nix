{ wlib }:
{ ... }: {
  imports = [
    (wlib.getInstallModule {
      name = "neovim";
      value = wlib.wrapperModules.neovim;
    })
  ];
  wrappers.neovim = { pkgs, lib, ... }: {
    enable = true;
    binName = "testob";

    settings = {
      config_directory = ./.;
      buildEnv.packages = true;
      dont_link = true;
      block_normal_config = true;
      compile_generated_lua = true;
    };
  };
}
