{ config, lib, pkgs, ... }:
with builtins; with lib;
{
  options.nzbr.boot = with types; {
    initrdSecrets = mkOption {
      type = attrsOf string;
      default = { };
    };
  };

  config =
    let
      cfg = config.nzbr.boot.initrdSecrets;
      useAge = config.nzbr.agenix.enable;
      isAgeSecret = dst: src: (useAge && hasSuffix ".age" src);
      isPlainSecret = dst: src: !(isAgeSecret dst src);
      ageSecrets = filterAttrs isAgeSecret cfg;
      plainSecrets = filterAttrs isPlainSecret cfg;
      encryptedPath = dst: "secrets/${dst}.age";
      sshKey = "/ssh_host_ed25519_key";
    in
    mkIf ((length (attrNames cfg)) > 0) {
      boot.initrd.preDeviceCommands = mkIf useAge
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
        # Secrets that are located in the flake are copied to a derivation first,
        # because the flake source will get garbage collected. Because of this,
        # building the initrd for old generations would fail
        let
          root = config.nzbr.flake.root;

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
        // (mkIf useAge { ${sshKey} = "/etc/ssh/ssh_host_ed25519_key"; });
    };
}
