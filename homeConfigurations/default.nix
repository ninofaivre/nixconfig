{ lib, ... }@args: extraSpecialArgs: let
  mkHosts = hostpaths: lib.genAttrs' hostpaths (hostpath:
    lib.nameValuePair
      (builtins.baseNameOf hostpath)
      (import hostpath args extraSpecialArgs)
  );
  mkUser = userpath: lib.nameValuePair (builtins.baseNameOf userpath) (mkHosts (import userpath));
  mkUsers = userpaths: lib.concatMapAttrs (username: hosts:
    lib.mapAttrs' (hostname: hostconfig:
      lib.nameValuePair "${username}@${hostname}" hostconfig
    ) hosts
  ) (lib.genAttrs' userpaths mkUser);
in mkUsers [
  ./nino
]
