{lib, ...}:
with builtins; with lib; {
  types = with types; {
    strOrPathType = oneOf [ str (coercedTo path toString str) ];
    resourceType = addCheck (attrsOf anything) # These apply to all k8s resources I can think of right not, this may need to be changed
      (val:
        val ? apiVersion && isString val.apiVersion
        && val ? kind && isString val.kind
        && val ? spec
      );
    deploymentType = submodule {
      options = {
        enable = mkEnableOption "this deployment";
        steps = mkOption {
          type = listOf (oneOf [ strOrPathType resourceType ]);
        };
      };
    };
  };
}
