{ lib }:
{
  lzeLoad = plugin: config: {
    data = plugin;
    config = /*lua*/ ''
      require('lze').load((function(data)
        table.insert(data, 1, '${plugin.pname}')
        return data
      end)(${lib.generators.toLua {} (builtins.removeAttrs config [ "init" ])}))

      ${config.init or ""}
    '';
  };
}
