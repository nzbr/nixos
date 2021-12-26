{ pkgs, inputs, ... }:
pkgs.writeShellScriptBin "," ''
  exec ${pkgs.nixUnstable}/bin/nix run ${inputs.nixpkgs}#"$@"
''
