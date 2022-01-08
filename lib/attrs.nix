{ lib, ... }:
{
  orElse = set: attr: fallback:
    if builtins.hasAttr attr set
    then set.${attr}
    else fallback;

  orEmpty = set: attr:
    lib.orElse set attr { };
}
