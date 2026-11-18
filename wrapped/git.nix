{ wlib, ... }@args: {
  imports = [ wlib.wrapperModules.git ];
  settings = {
    user.name = "6e696e6f";
    user.email = "git@6e696e6f.dev";
    safe.directory = "/etc/nixos";
  };
  install.modules.nixos = { config, ... }:
  let
    cfg = args.config.install.getWrapperConfig config;
  in
  {
    # TODO PR
    # pros : libgit2 uses the git wrapper config when installed
    # cons : might be confusing if trying to launch for instance nixpkgs#git ?
    environment.etc."gitconfig".source = "${cfg.wrapper}/gitconfig";
  };
}
