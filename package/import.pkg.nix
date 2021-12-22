{ pkgs }:
pkgs.writeShellScriptBin "import" ''
  args=("$@")
  exec ${pkgs.nixUnstable}/bin/nix shell ''${args[@]/#/\/run/inputs/nixpkgs#}
''
