{ options, config, lib, pkgs, inputs, ... }:
with lib;
let
  servers = import ./servers.conf;
in
{
  options.nzbr.service.mullvad-bridge = {
    enable = mkEnableOption "Mullvad OVPN Bridge";
    enabledRegions = mkOption {
      type = types.listOf types.str;
      default = attrNames servers;
      description = "List of servers to enable";
    };
    bridges = mkEnableOption "create bridge interfaces for each region to attach other containers to";
    tailscale = mkEnableOption "Tailscale Exit Node";
  };

  config =
    let
      cfg = config.nzbr.service.mullvad-bridge;

      bridgeExternal = "br-mv-external";
      container = server: "mullvad-${server}";
      bridge = server: "br-mv-${server}";
    in
    mkIf cfg.enable (
      {
        networking.bridges = {
          ${bridgeExternal}.interfaces = [ ];
        } // (optionalAttrs cfg.bridges
          (mapListToAttrs
            (server: {
              name = bridge server;
              value = { interfaces = [ ]; };
            })
            cfg.enabledRegions
          )
        );

        networking.interfaces = {
          ${bridgeExternal}.ipv4.addresses = [{ address = "192.168.123.1"; prefixLength = 24; }];
        } // (optionalAttrs cfg.bridges
          (mapListToAttrs
            (server: {
              name = bridge server;
              value = { ipv4.addresses = [ ]; };
            })
            cfg.enabledRegions
          )
        );

        networking.nat = {
          enable = true;
          internalInterfaces = [ bridgeExternal ];
        };

        systemd.services = {
          "container@".after = [ "network.target" ];
        } // (mapListToAttrs
          (server: {
            name = "container@${container server}";
            value = { requires = [ "network-addresses-br-mv-external.service" ] ++ (optional cfg.bridges "network-addresses-br-mv-${server}.service"); };
          })
          cfg.enabledRegions
        );

        containers = foldl recursiveUpdate { } (
          map
            ({ index, value }:
              {

                "${container value}" = {
                  autoStart = true;
                  ephemeral = true;
                  specialArgs = { inherit lib; };

                  enableTun = true;
                  privateNetwork = true;
                  hostBridge = bridgeExternal;
                  localAddress = "192.168.123.${toString (index + 2)}/24";
                  extraVeths.internal = mkIf cfg.bridges {
                    localAddress = "192.168.234.1/24";
                    hostBridge = bridge value;
                  };
                  bindMounts = {
                    "/etc/ssh" = { hostPath = "/etc/ssh"; isReadOnly = true; };
                  };

                  config = { ... }: {
                    imports = [
                      inputs.agenix.nixosModules.age
                      ../tailscale.nix
                    ];

                    options.nzbr.assets = options.nzbr.assets;

                    config = {
                      age = config.age;
                      nzbr.assets = config.nzbr.assets;

                      networking = {
                        interfaces.eth0.ipv4.routes = map
                          (ip: {
                            via = "192.168.123.1";
                            address = ip;
                            prefixLength = 32;
                          })
                          servers.${value};
                        nat = {
                          enable = true;
                          externalInterface = "mullvad";
                          internalInterfaces = [ "internal" ];
                        };
                      };

                      services.openvpn.servers.mullvad = {
                        config = ''
                          client
                          dev mullvad
                          dev-type tun
                          resolv-retry infinite
                          nobind
                          persist-key
                          persist-tun
                          verb 3
                          remote-cert-tls server
                          ping 10
                          ping-restart 60
                          sndbuf 524288
                          rcvbuf 524288
                          cipher AES-256-GCM
                          tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384
                          proto udp
                          auth-user-pass ${config.nzbr.assets."mullvad_userpass.txt"}
                          ca ${./mullvad_ca.crt}
                          tun-ipv6
                          script-security 2
                          fast-io
                          remote-random
                          ${concatStringsSep "\n" (map (ip: "remote ${ip} 1195") servers.${value})}
                        '';
                        up = "echo nameserver $nameserver | ${pkgs.openresolv}/sbin/resolvconf -m 0 -a $dev";
                        down = "${pkgs.openresolv}/sbin/resolvconf -d $dev";
                      };

                      nzbr.service.tailscale = mkIf cfg.tailscale {
                        enable = true;
                        exit = true;
                        authkey = config.nzbr.assets."bridge.tskey";
                      };

                      system.stateVersion = config.system.stateVersion;
                    };

                  };
                };

              }
            )
            (zipWithIndex 0 cfg.enabledRegions)
        );
      }
    );
}
