{ vimPlugins, lzeLoad, lzeDepOf, toLuaLib, dep_of, ... }:
with vimPlugins;
with toLuaLib;
{
  lazy = true;
  data = [
    (lzeLoad telescope-fzf-native-nvim {
      dep_of = lzeDepOf telescope-nvim;
    })
    (lzeLoad telescope-nvim {
      inherit dep_of;
      cmd = [
        "Telescope"
      ];
      keys = map (el: [
        "<leader>${el.keys}"
        (lambda0 (pipe1 (require "telescope.builtin") (call1 el.builtin (el.opts or {}))))
        (nf "desc" (el.desc or "Telescope ${el.builtin} builtin"))
      ]) [
        { keys = "k"; builtin = "keymaps"; }
        {
          keys = "mk";
          builtin = "keymaps";
          opts.lhs_filter = lambda ["lhs"] (raw "return lhs:match('^' .. vim.g.mapleader)");
          desc = "Display My Keymaps via telescope keymaps builtin";
        }
        { keys = "ff"; builtin = "find_files"; }
        { keys = "b"; builtin = "buffers"; }
        { keys = "gf"; builtin = "git_files"; }
      ];
      after = lambda ["plugin"] (raw ''
        for _, ext in ipairs({ 'fzf', 'notify', }) do
          require('telescope').load_extension(ext)
        end
      '');
    })
  ];
}
