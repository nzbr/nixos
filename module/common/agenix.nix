{ config, lib, inputs, system, root, assets, host, ... }:
with builtins; with lib;
let
  find = dir: map (name: removePrefix "${dir}/" name) (findModules "" dir);
  commonAssets = find "${assets}";
  hostAssets = find "${host}";
  allAssets = commonAssets ++ hostAssets;

  findAsset = name: (if elem name hostAssets then "${host}" else "${assets}") + "/${name}";
in
{
  options.nzbr = {
    assets = with types; mkOption {
      type = attrsOf str;
      default = listToAttrs (
        map
          (file:
            let
              file' = unsafeDiscardStringContext (removeSuffix ".age" file);
            in
            {
              name = file';
              value =
                if hasSuffix ".age" file
                then config.age.secrets.${file'}.path
                else findAsset file;
            }
          )
          allAssets
      );
    };
    foreignAssets = with types; mkOption {
      type = attrsOf (attrsOf str);
      default = listToAttrs (
        map
          (host: nameValuePair' host inputs.self.packages.${system}.nixosConfigurations.${host}.config.nzbr.assets)
          (attrNames inputs.self.packages.${system}.nixosConfigurations)
      );
    };
  };

  config = {
    age = {
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_rsa_key"
      ];
      secrets = listToAttrs (
        map
          (file:
            nameValuePair'
              (removeSuffix ".age" file)
              { file = findAsset file; }
          )
          (
            filter
              (name: hasSuffix ".age" name)
              allAssets
          )
      );
    };
  };
}
