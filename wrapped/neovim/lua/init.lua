-- default tabs, for new file where guess-indent have nothing to guess
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2

vim.opt.expandtab = true

vim.opt.number = true
vim.g.mapleader = ' '

-- term remap
vim.api.nvim_set_keymap('t', '<C-w>', '<C-\\><C-n><C-w>', { noremap = true, })
