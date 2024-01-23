{ lib, ... }:
with lib; {
  zipWithIndex = idx: xs:
    if xs == [ ]
    then [ ]
    else [{ index = idx; value = head xs; }] ++ (zipWithIndex (idx + 1) (tail xs));
}
