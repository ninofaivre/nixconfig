{ wlib, ... }: {
  imports = [ wlib.wrapperModules.git ];
  settings = {
    user.name = "6e696e6f";
    user.email = "git@6e696e6f.dev";
    safe.directory = "/etc/nixos";
  };
}
