{
  description = "Home Manager configuration of nino";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "nixpkgs/release-26.05";
    wrappers.url = "github:BirdeeHub/nix-wrapper-modules";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, wrappers, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
      wlib = wrappers.lib;
    in
    {
      packages.${system} = {
        # testob = self.homeConfigurations."nino".config.wrappers.neovim.package;
        # testob = self.homeConfigurations."nino".config.wrappers.neovim.finalPackage;
        testob = (wrappers.wrappers.neovim.wrap {
          inherit pkgs;
          binName = "testob";
        
          settings = {
            config_directory = ./neovim;
            buildEnv.packages = true;
            dont_link = true;
            block_normal_config = true;
            compile_generated_lua = true;
          };
        });
        # testob = wlib.getWrapper pkgs wlib.wrapperModules.neovim {
        #   enable = true;
        #   binName = "testob";
        #
        #   settings = {
        #     config_directory = ./.;
        #     buildEnv.packages = true;
        #     dont_link = true;
        #     block_normal_config = true;
        #     compile_generated_lua = true;
        #   };
        # };
      };
      apps.${system} = {
        testob = {
          type = "app";
          program = lib.getExe' self.packages.${system}.testob "testob";
        };
      };
      homeConfigurations."nino" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./home.nix
          (import ./neovim { inherit wlib; })
          # (import ./nixCats { inherit nixCats; inherit (self) inputs; })
        ];
      };
    };
}
