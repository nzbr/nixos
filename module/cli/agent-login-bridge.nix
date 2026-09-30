{ config, lib, pkgs, ... }:
with lib;
let
  opener =
    if config.nzbr.pattern.wsl.enable then
      pkgs.writeShellScript "agent-login-wsl-open" ''
        if [ -z "''${WSL_INTEROP:-}" ] || [ ! -S "$WSL_INTEROP" ]; then
          unset WSL_INTEROP
          for interop in /run/WSL/*_interop; do
            if [ ! -L "$interop" ] && [ -S "$interop" ]; then
              export WSL_INTEROP="$interop"
              break
            fi
          done
        fi

        if [ -z "''${WSL_INTEROP:-}" ]; then
          echo "agent-login-wsl-open: no WSL interop socket found" >&2
          exit 127
        fi

        export PATH="${config.wsl.wslConf.automount.root}/c/Windows/System32/WindowsPowerShell/v1.0:$PATH"
        url=''${1//\'/\'\'}
        exec powershell.exe -NoProfile -NonInteractive \
          -Command "Start-Process -FilePath '$url'"
      ''
    else
      lib.getExe' pkgs.xdg-utils "xdg-open";
in
{
  options.nzbr.cli.agent-login-bridge.enable = mkEnableOption "Agent login bridge";

  config = mkIf config.nzbr.cli.agent-login-bridge.enable {
    nzbr.home.config = {
      programs.bash.bashrcExtra = mkIf config.nzbr.pattern.wsl.enable ''
        systemctl --user import-environment WSL_INTEROP 2>/dev/null || true
      '';

      systemd.user = {
        sockets.agent-login = {
          Socket = {
            ListenStream = "%t/agent-login.sock";
            SocketMode = "0600";
            Accept = true;
          };
          Install.WantedBy = [ "sockets.target" ];
        };

        services."agent-login@" = {
          Unit.Description = "Open an agent harness login URL from a COI container and relay the callback back";
          Service = {
            Type = "simple";
            ExecStart = "${lib.getExe pkgs.python3} ${./agent-login-bridge.py}";
            StandardInput = "socket";
            # Keep protocol output off the socket connection
            StandardOutput = "journal";
            StandardError = "journal";
            # Socket units do not inherit the graphical session bus address
            Environment = [
              "DBUS_SESSION_BUS_ADDRESS=unix:path=%t/bus"
              "AGENT_LOGIN_OPENER=${opener}"
            ];
            # Timeout unfinished logins
            RuntimeMaxSec = 600;
            # Do not kill a browser started by xdg-open
            KillMode = "process";
          };
        };
      };
    };
  };
}
