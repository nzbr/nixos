{ pkgs }:
pkgs.writeShellScriptBin "," ''
  exec ${pkgs.nixUnstable}/bin/nix run /run/inputs/nixpkgs#"$@"
''
