{ naersk, inputs, ... }:
naersk.buildPackage {
  pname = "wsld";
  root = inputs.wsld;
  cargoBuildOptions = (default: default ++ [ "-p" "wsld" ]);
}
