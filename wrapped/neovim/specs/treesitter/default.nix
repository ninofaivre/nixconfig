{ lib, lzeLoad, nvim-treesitter, mkPlugin }:
  let
    inherit (lib.generators) mkLuaInline toLua;
    queries = mkPlugin "queries" (lib.fileset.toSource {
      root = ./.;
      fileset = ./queries;
    });
  in
  [
    (lzeLoad queries { dep_of = "nvim-treesitter"; })
    (lzeLoad nvim-treesitter.withAllGrammars (let
      grammars = builtins.attrNames nvim-treesitter.grammarPlugins;
    in {
      ft = grammars;
      after = mkLuaInline ''function(plugin)
        -- Disabling manual grammar install, thus using only nix.
        require('nvim-treesitter').setup({ install_dir = '/invalid', })

        vim.api.nvim_create_autocmd('FileType', {
          -- Group is mandatory so the cmd can be triggered even on first ft event, after lze.
          group = vim.api.nvim_create_augroup("ts", { clear = true, }),
          pattern = ${toLua {} grammars},
          callback = function (args)
            vim.treesitter.start()
            -- Indent can be disabled for some fts w/ args.match.
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end,
        })
      end'';
    }))
  ]
