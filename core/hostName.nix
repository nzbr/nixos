{ lib, hostName, ... }:
with builtins; with lib; {
  networking.hostName = hostName;
}
