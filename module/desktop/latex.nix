{ config, lib, pkgs, modulesPath, ... }:
{
  environment.systemPackages = with pkgs; [
    pandoc
    pandoc-plantuml-filter

    (texlive.combine {
      inherit (texlive)
        scheme-medium

        adjustbox
        bidi
        bookmark
        booktabs
        caption
        csquotes
        dinbrief
        fancyvrb
        float
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
        # pgfpages
        polyglossia
        # scrlayer-scrpage
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
        # xeCJK
        xpatch
        zref
        ;
    })

    # ragon.pandocode
  ];
}
