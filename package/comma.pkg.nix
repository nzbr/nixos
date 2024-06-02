{ pkgs, inputs, ... }:
pkgs.writeShellScriptBin "," ''
  exec ${pkgs.nix}/bin/nix run ${inputs.nixpkgs}#"$@"
''
