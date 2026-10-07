{
  description = "My nvim config, is its own flake/flake.lock to isolate plugins version...";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";

    # extra nvim plugins
    system-theme = { url = "github:cosmicboots/system-theme.nvim"; flake = false; };
    lua-dbus_proxy = { # system-theme dep
      url = "github:stefano-m/lua-dbus_proxy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,

    # extra nvim plugins
    system-theme, lua-dbus_proxy,
    ...
  }: {
    lib.mkPkgs = system: import nixpkgs {
      inherit system;
      overlays = [ lua-dbus_proxy.overlays.default ];
    };
    lib.nvimModule = import ./default.nix {
      extraVimPluginsInputs = {
        inherit system-theme;
      };
    };
  };
}
