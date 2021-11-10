{ pkgs }:
pkgs.writeShellScriptBin "import" ''
  exec ${pkgs.nixUnstable}/bin/nix shell /run/inputs/nixpkgs#''${1}
''
