{
  pkgs,
  home-manager,
  lib,
  config,
  ...
}:
let
  start-haven = pkgs.writeShellScriptBin "start-haven" (builtins.readFile ./start-haven.sh);

  subdomains = [
    config.secrets.services.airsonic.url
    config.secrets.services.cache.url
    config.secrets.services.forgejo.url
    config.secrets.services.gremlin-lab.url
  ];
in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.05";

  host = {
    role = "server";
    services = {
      acme = {
        enable = true;
        defaultEmail = config.secrets.users.aires.email;
        certs = {
          "${config.secrets.networking.primaryDomain}" = {
            dnsProvider = "namecheap";
            extraDomainNames = subdomains;
            webroot = null; # Required in order to prevent a failed assertion
            credentialFiles = {
              "NAMECHEAP_API_USER_FILE" = "${pkgs.writeText "namecheap-api-user" ''
                ${config.secrets.networking.namecheap.api.user}
              ''}";
              "NAMECHEAP_API_KEY_FILE" = "${pkgs.writeText "namecheap-api-key" ''
                ${config.secrets.networking.namecheap.api.key}
              ''}";
            };
          };
        };
      };
      apcupsd = {
        enable = true;
        configText = builtins.readFile ./etc/apcupsd.conf;
      };
      airsonic = {
        enable = true;
        home = "/storage/services/airsonic-advanced";
      };
      boinc.enable = true;
      cache = {
        enable = false; # Disable for now
        secretKeyFile = "/storage/services/nix-cache/cache-priv-key.pem";
      };
      duplicacy-web = {
        enable = true;
        autostart = false;
        environment = "/storage/backups/settings/Haven";
      };
      forgejo = {
        enable = true;
        home = "/storage/services/forgejo";
      };
      msmtp.enable = true;
      nginx = {
        enable = true;
        autostart = false;
        virtualHosts = {
          "${config.secrets.networking.primaryDomain}" = {
            default = true;
            enableACME = true; # Enable Let's Encrypt
            locations."/" = {
              # Catchall vhost, will redirect users to Forgejo
              return = "301 https://${config.secrets.services.forgejo.url}";
            };
          };
          "${config.secrets.services.gremlin-lab.url}" = {
            useACMEHost = config.secrets.networking.primaryDomain;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://${config.secrets.services.gremlin-lab.ip}";
              proxyWebsockets = true;
              extraConfig = "proxy_ssl_server_name on;";
            };
          };
        };
      };
      ssh = {
        enable = true;
        ports = [ config.secrets.hosts.haven.ssh.port ];
      };
      virtualization = {
        enable = true;
        user = "aires";
      };
    };
    users.aires = {
      enable = true;
      services.syncthing = {
        enable = true;
        autostart = false;
      };
    };
  };

  # TODO: VPN (Check out Wireguard)

  # Add Haven's startup script
  environment.systemPackages = [ start-haven ];

  # Allow Haven to be a build target for other architectures (mainly ARM64)
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Automatically update Flake configuration for other hosts to use
  systemd.services."nixos-update-flake" = {
    serviceConfig = {
      Type = "oneshot";
      User = config.users.users.aires.name;
    };
    script = ''
      set -eu
      cd ${config.users.users.aires.home}/Development/nix-configuration
      git pull --recurse-submodules
      nix flake update
      git add flake.lock
      git commit -m "Update flake.lock"
      git push
    '';
  };

  systemd.timers."nixos-update-flake-timer" = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = "true";
      Unit = "nixos-update-flake.service";
    };
  };
}
