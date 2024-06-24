{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.aux.system.services.k3s;
in
with lib;
{
  options = {
    aux.system.services.k3s = {
      enable = mkEnableOption (mdDoc "Enables K3s");
      role = mkOption {
        default = "server";
        type = types.enum [
          "agent"
          "server"
        ];
        description = "Which K3s role to use";
      };
      serverAddr = mkOption {
        default = "";
        type = types.str;
        description = "If an agent, this is the address of the server.";
      };
    };
  };

  config = mkIf cfg.enable {
    # Add packages for developing with K3s.
    # For details, see https://nixos.wiki/wiki/K3s
    environment.systemPackages = with pkgs; [ k3s ];

    networking.firewall = {
      allowedTCPPorts = [
        6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
        # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
        # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
      ];
      allowedUDPPorts = [
        # 8472 # k3s, flannel: required if using multi-node for inter-node networking
      ];
    };

    services.k3s = {
      enable = true;
      inherit (cfg) role;
      extraFlags = toString [
        # "--kubelet-arg=v=4" # Optionally add additional args to k3s
      ];
    } // optionalAttrs (cfg.role == "agent") { inherit (cfg) serverAddr; };

    # Increase number of open file handlers so K3s doesn't exhaust them...again.
    systemd.extraConfig = ''
      DefaultLimitNOFILE=8192:1048576
    '';
  };
}
