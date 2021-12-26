{ pkgs, inputs, ... }:
pkgs.writeShellScriptBin "import" ''
  args=("$@")
  exec ${pkgs.nixUnstable}/bin/nix shell ''${args[@]/#/\${inputs.nixpkgs}#}
''
