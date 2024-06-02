{ pkgs, inputs, ... }:
pkgs.writeShellScriptBin "import" ''
  args=("$@")
  exec ${pkgs.nix}/bin/nix shell ''${args[@]/#/\${inputs.nixpkgs}#}
''
