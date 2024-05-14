{
  pkgs,
  home-manager,
  lib,
  config,
  ...
}:
let
  start-haven = pkgs.writeShellScriptBin "start-haven" (builtins.readFile ./start-haven.sh);
in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.05";
  system.autoUpgrade.enable = lib.mkForce false;

  host = {
    role = "server";
    apps.development.kubernetes.enable = true;
    services = {
      apcupsd.enable = true;
      duplicacy-web = {
        enable = true;
        autostart = false;
        environment = "${config.users.users.aires.home}";
      };
      k3s = {
        enable = true;
        role = "server";
      };
      msmtp.enable = true;
    };
    users = {
      aires = {
        enable = true;
        services = {
          syncthing = {
            enable = true;
            autostart = false;
          };
        };
      };
      media.enable = true;
    };
  };

  # Enable SSH
  services.openssh = {
    enable = true;
    ports = [ 33105 ];

    settings = {
      # require public key authentication for better security
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = true;

      PermitRootLogin = "without-password";
    };
  };

  boot = {
    # Enable mdadm for Sapana (RAID 5 primary storage)
    swraid = {
      enable = true;
      # mdadmConf configured in nix-secrets
    };

    # Allow Haven to be a build target for other architectures (mainly ARM64)
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  # Open port for OpenVPN
  networking.firewall.allowedUDPPorts = [ 1194 ];

  # Add script for booting Haven
  environment.systemPackages = [ start-haven ];
}
