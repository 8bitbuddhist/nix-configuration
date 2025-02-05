{ config, pkgs, ... }:

let
  port = 8022;
in
{
  environment = {
    etc."ssh/sshd_config".source = ./sshd_config;
    packages = [
      (pkgs.writeScriptBin "sshd-start" ''
        #!${pkgs.runtimeShell}

        echo "Starting sshd in non-daemonized way on port ${toString port}"
        ${pkgs.openssh}/bin/sshd -f "/etc/ssh/sshd_config" -D
      '')
    ];
  };
}
