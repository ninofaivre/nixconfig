{ pkgs, lib, extraVimPlugins, nvim-lib }:
with pkgs.vimPlugins;
with extraVimPlugins;
with (import ./utils.nix { inherit lib; });
let
  inherit (lib.generators) mkLuaInline toLua;
in
{
  startup = [
    lze
  ];

  treesitter = {
    lazy = true;
    data = import ./treesitter {
      inherit lib lzeLoad nvim-treesitter;
      inherit (nvim-lib) mkPlugin;
    };
  };

  general = {
    lazy = true;
    data = [
      (lzeLoad guess-indent-nvim {
        ft = "*";
        after = mkLuaInline "function(plugin) require('guess-indent').setup() end";
      })
      (lzeLoad nvim-notify {
        on_require = "notify";
        after = mkLuaInline "function(plugin) vim.notify = require('notify') end";
        init = /*lua*/ ''
          vim.notify = function(...)
            return require('notify')(...)
          end
        '';
      })
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
}
