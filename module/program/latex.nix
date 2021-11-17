{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.program.latex = {
    enable = mkEnableOption "LaTeX";
  };

  config = mkIf config.nzbr.program.latex.enable {
    environment.systemPackages = with pkgs; [
      pandoc
      pandoc-plantuml-filter

      (texlive.combine {
        inherit (texlive)
          scheme-medium

          academicons
          adjustbox
          arydshln
          bidi
          bookmark
          booktabs
          caption
          circuitikz
          csquotes
          dinbrief
          fancyvrb
          float
          fontawesome5
          footmisc
          footnotebackref
          fvextra
          hyperref
          listings
          ly1
          mathspec
          mdframed
          moderncv
          multirow
          needspace
          parskip
          pagecolor
          polyglossia
          selnolig
          setspace
          sourcesanspro
          sourcecodepro
          stmaryrd
          titling
          ulem
          unicode-math
          upquote
          xcolor
          xpatch
          zref
          ;
      })
    ];
  };
}
