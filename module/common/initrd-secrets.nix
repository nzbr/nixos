{ config, lib, pkgs, root, ... }:
with builtins; with lib;
{
  options = with types; {
    nzbr.initrdSecrets = mkOption {
      type = attrsOf string;
      default = { };
    };
  };

  config =

    let
      cfg = config.nzbr.initrdSecrets;
      ageSecrets = (filterAttrs (dst: src: hasSuffix ".age" src) cfg);
      plainSecrets = (filterAttrs (dst: src: !(hasSuffix ".age" src)) cfg);
      encryptedPath = dst: "secrets/${dst}.age";
      sshKey = "/ssh_host_ed25519_key";
    in
    mkIf ((length (attrNames cfg)) > 0) {
      boot.initrd.preDeviceCommands =
        (
          concatStringsSep "\n" (
            [ "set -x" ]
            ++
            (mapAttrsToList
              (dst: src:
                "${pkgs.rage}/bin/rage -i ${sshKey} -o /${dst} -d ${encryptedPath dst}"
              )
              ageSecrets
            )
            ++
            [ "set +x" ]
          )
        );

      boot.initrd.secrets =
        let
          secretFiles = (
            plainSecrets
            //
            (mapAttrs' (dst: src: nameValuePair' (encryptedPath dst) src) ageSecrets)
          );
          drvSecrets = filterAttrs
            (
              dst: src: (hasPrefix root src)
            )
            secretFiles;
          rootSecrets = filterAttrs
            (
              dst: src: !(hasPrefix root src)
            )
            secretFiles;
          drv = pkgs.callPackage
            (
              { stdenv }: stdenv.mkDerivation {
                pname = "initrd-secrets";
                version = "";

                src = root;

                installPhase =
                  concatStringsSep "\n" (
                    [ "set -x" ]
                    ++
                    flatten (
                      mapAttrsToList
                        (dst: src: [
                          "mkdir -p ''$(dirname \"$out/secret/${dst}\")"
                          "cp \"${src}\" \"$out/secret/${dst}\""
                        ])
                        drvSecrets
                    )
                    ++
                    [ "set +x" ]
                  );
              }
            )
            { };
        in
        (
          mapAttrs'
            (
              dst: src:
                nameValuePair'
                  dst
                  "${drv}/secret/${dst}"
            )
            drvSecrets
        )
        // rootSecrets
        // { sshKey = "/etc/ssh/ssh_host_ed25519_key"; };
    };
}
