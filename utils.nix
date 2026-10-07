{ pkgs, lib }:
{
  gl = pkg: pkgs.runCommand pkg.name {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    inherit (pkg) meta;
  } ''
    makeWrapper "${lib.getExe pkgs.nixgl.nixGLIntel}" $out/bin/${pkg.name} \
    --add-flags ${lib.getExe pkg}
  '';
}
