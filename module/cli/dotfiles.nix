{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {

  options.nzbr.cli.dotfiles = with types; {
    enable = mkEnableOption "nzbr's dotfiles";
  };

  config =
    let
      cfg = config.nzbr.cli.dotfiles;
      extraPath = concatStringsSep ":" (flatten (map (pkg: [ "${pkg}/bin" "${pkg}/sbin" ]) config.environment.systemPackages));
    in
    mkIf cfg.enable {

      nzbr.home.config.home.file =
        let
          drv = pkgs.runCommand "dotfiles" { nativeBuildInputs = [ pkgs.xstow ]; } ''
            mkdir -p $out
            cp -r "${inputs.dotfiles}/." $out/.dotfiles
            export HOME=$out
            mkdir -p $HOME/{.cache,.config,.local/{bin,share,lib}}
            touch $HOME/{.cache,.config,.local/{bin,share,lib}}/.stowkeep
            PATH=$PATH:${extraPath}
            export DOT_NOINSTALL=1 && source $HOME/.dotfiles/control.sh && autolink_all
            rm -f $HOME/{.cache,.config,.local/{bin,share,lib}}/.stowkeep
            sha256sum $HOME/.zsh_plugins.txt $HOME/.zshrc > $HOME/.zsh.sha
            mkdir -p "$HOME/.cache/antibody"
            ln -sf "${pkgs.antibody}/bin/antibody" "$HOME/.cache/antibody/antibody"
          '';
          createFileEntries = dir:
            flatten (
              mapAttrsToList
                (n: v:
                  if v == "directory"
                  then createFileEntries "${dir}/${n}"
                  else
                    let
                      file = unsafeDiscardStringContext (removePrefix "${drv}/" "${dir}/${n}");
                    in
                    {
                      name = "dotfiles-${replaceStrings ["/"] ["-"] file}";
                      value = {
                        target = file;
                        source = "${dir}/${n}";
                      };
                    }
                )
                (readDir dir)
            );
        in
        listToAttrs (createFileEntries drv);
    };

}
