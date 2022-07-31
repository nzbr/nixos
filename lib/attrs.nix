{ lib, ... }:
with builtins; with lib; {
  orElse = set: attr: fallback:
    if builtins.hasAttr attr set
    then set.${attr}
    else fallback;

  orEmpty = set: attr:
    lib.orElse set attr { };

  # Maps a list to an attrset
  mapListToAttrs = mapper: list: listToAttrs (map mapper list);
}
