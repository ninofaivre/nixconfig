{ nixCats, inputs }:
{ config, lib, ... }: let
  inherit (nixCats) utils;
in {
  imports = [ nixCats.homeModule ];
  config.nixCats = {
    enable = true;
    addOverlays = [ (utils.standardPluginOverlay inputs) ];

    packageNames = [ "testoa" ];
    luaPath = ./lua;

    categoryDefinitions.replace = ({ pkgs, settings, categories, extra, name, mkPlugin, ... }@packageDef: {
      lspsAndRuntimeDeps  = with pkgs; {
        general = [
          lazygit
        ];
        lua = [
          lua-language-server
          stylua
        ];
        nix = [
          nixd
          alejandra
        ];
        go = [
          gopls
          delve
          golint
          golangci-lint
          gotools
          go-tools
          go
        ];
      }; 
      startupPlugins = {
        general = with pkgs.vimPlugins; [
          lze
          lzextras
          snacks-nvim
          onedark-nvim
          remote-sshfs-nvim
        ];
      };
      optionalPlugins = with pkgs.vimPlugins; {
        go = [
          nvim-dap-go
        ];
        lua = [
          lazydev-nvim
        ];
        general = [
          indent-o-matic
          nvim-lspconfig
          blink-cmp
          nvim-treesitter.withAllGrammars
          lualine-nvim
          lualine-lsp-progress
          blink-cmp
          gitsigns-nvim
          nvim-lint
          conform-nvim
          nvim-dap
          nvim-dap-ui
          nvim-dap-virtual-text
          which-key-nvim
        ];
      };
      sharedLibraries = { general = with pkgs; [ ]; };
      environmentVariables = {};
      extraWrapperArgs = {};
    });
    packageDefinitions.replace = {
      testoa = ({pkgs, name, ...}: {
        settings = {
          suffix-path = true;
          suffix-LD = true;
          wrapRc = "WRAPRC";
          aliases = [ "testob" "testoc" ];
          hosts.node.enable = true;
        };
        categories = { general = true; lua = true; nix = true; go = true; };
        extra = {
          nixdExtras.nixpkgs = ''import ${pkgs.path} {}'';
        };
      });
    };
  };
}
