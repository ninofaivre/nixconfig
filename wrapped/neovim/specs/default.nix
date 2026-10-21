{ lib, vimPlugins, nvim-lib, toLuaLib }@inputs:
with (import ./utils.nix inputs);
with vimPlugins;
with toLuaLib;
{
  startup = [
    lze
    nix-develop-nvim
  ];

  treesitter = lzeImport ./treesitter {};

  telescope = lzeImport ./telescope.nix {
    dep_of = lzeDepOf [ remote-sshfs-nvim ];
  };

  general = {
    lazy = true;
    data = [
      (lzeLoad guess-indent-nvim {
        ft = "*";
        after = lambda ["plugin"] (raw "require('guess-indent').setup()");
      })
      (lzeLoad nvim-notify {
        on_require = "notify";
        dep_of = lzeDepOf [ telescope-nvim ];
        after = lambda ["plugin"] (raw "vim.notify = require('notify')");
        beforeAll = lambda0 (raw ''
          vim.notify = function(...)
            return require('notify')(...)
          end
        '');
      })
      (lzeLoad plenary-nvim {
        dep_of = lzeDepOf [
          remote-sshfs-nvim
          telescope-nvim
        ];
      })
      (lzeLoad remote-sshfs-nvim {
        cmd = [
          "RemoteSSHFSConnect"
          "RemoteSSHFSDisconnect"
        ];
        keys = [
          [ "<leader>rc" ":RemoteSSHFSConnect<CR>" (nf "desc" "Connect to remote SSH host FS") ]
          [ "<leader>rd" ":RemoteSSHFSDisconnect<CR>" (nf "desc" "Disconnect from remote SSH host FS") ]
        ];
        after = lambda ["plugin"] (raw ''
          require('remote-sshfs').setup({})
          require('telescope').load_extension('remote-sshfs')
        '');
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
        vim.system(
          { 'busctl', '--user', 'status', 'org.freedesktop.portal.Desktop' },
          { stdout = false, stderr = false, },
          function (res)
            if res.code ~= 0 then return end
            vim.schedule(function ()
              require('system-theme').setup({
                light_theme = 'catppuccin-latte',
                dark_theme = 'catppuccin-frappe',
              })
            end)
          end
        )
      '';
    }
  ];
}
