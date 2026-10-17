{ lib, vimPlugins, nvim-lib, toLuaLib, ... }:
let
  callWith = autoArgs: fn: args:
    let
      f = if lib.isFunction fn then fn else import fn;
    in
    f (builtins.intersectAttrs (lib.functionArgs f) autoArgs // args);
  utils = {
    lzeDepOf = dep: map lib.getName (lib.toList dep);
    lzeLoad = plugin: config: {
      data = plugin;
      config = /*lua*/ ''
        require('lze').load((function(data)
          table.insert(data, 1, '${lib.getName plugin}')
          return data
        end)(${toLuaLib.toLua config}))
      '';
    };
    lzeImport = callWith (utils // {
      inherit vimPlugins lib toLuaLib;
      inherit (nvim-lib) mkPlugin;
    });
  };
in
utils
  # lzeImport = callWith (vimPlugins // {
  #   inherit lib lzeLoad lzeDepOf;
  #   inherit (lib.generators) mkLuaInline toLua;
  #   inherit (nvim-lib) mkPlugin;
  # });
