{ extraVimPluginsInputs, ... }:
{ wlib, config, lib, pkgs, ... }: let
  extraVimPlugins = lib.mapAttrs config.nvim-lib.mkPlugin extraVimPluginsInputs;
in {
  imports = [ wlib.wrapperModules.neovim ];
  hosts.neovide.nvim-host = {
    enable = true;
  };

  env = {
    GI_TYPELIB_PATH = "${lib.getLib pkgs.glib}/lib/girepository-1.0/"; #systeme-theme dep
  };

  runtimePkgs = with pkgs; [
  ];
  runtimeLibs = with pkgs; [
  ];

  settings = {
    config_directory = ./lua;
    buildEnv.packages = true;

    dont_link = true;
    block_normal_config = true;
    compile_generated_lua = true;

    nvim_lua_env = lp: with lp; with pkgs.luajitPackages; [
      dbus_proxy
    ];
  };

  specs = with pkgs.vimPlugins; with extraVimPlugins; {
    startup = [
      lze
    ];
    lazy = {
      lazy = true;
      data = let
        lze = plugin: data: /*lua*/ ''
          require('lze').load({
            '${plugin.pname}',
            ${data}
          })
        '';
      in
      [
        {
          data = nvim-treesitter.withAllGrammars;
          config = let
            luaGrammarsList = lib.generators.toLua {} (lib.unique (map (g:
              lib.replaceStrings ["-"] ["_"] (lib.removePrefix "tree-sitter-" g)
            ) (builtins.attrNames nvim-treesitter.builtGrammars)));
          in lze nvim-treesitter /*lua*/ ''
            ft = ${luaGrammarsList},
            after = function(plugin)
              local ts = require('nvim-treesitter')
              ts.setup({
                highlight = { enable = true, },
                incremental_selection = { enable = true, },
                auto_install = false,
                parser_install_dir = nil,
              })
              vim.api.nvim_create_autocmd('FileType', {
                pattern = ${luaGrammarsList},
                callback = function() vim.treesitter.start() end,
              })
              vim.treesitter.start()
            end
          '';
        }
        {
          data = guess-indent-nvim;
          config = lze guess-indent-nvim /*lua*/ ''
            ft = '*',
            after = function(plugin)
              require('guess-indent').setup()
            end
          '';
        }
        {
          data = nvim-notify;
          config = /*lua*/ ''
            ${lze nvim-notify /*lua*/ ''
              on_require = 'notify',
              after = function(plugin)
                vim.notify = require('notify')
              end,
            ''}
            vim.notify = function(...)
              return require('notify')(...)
            end
          '';
        }
      ];
    };
    theme = [
      {
        data = catppuccin-nvim;
        config = /*lua*/ ''
          require('catppuccin').setup({
            flavour = 'frappe',
          })
          vim.cmd.colorscheme('catppuccin')
        '';
      }
      {
        data = system-theme;
        config = /*lua*/ ''
          require('system-theme').setup({
            light_theme = 'catppuccin-latte',
            dark_theme = 'catppuccin-frappe',
          })
        '';
      }
    ];
  };
}
