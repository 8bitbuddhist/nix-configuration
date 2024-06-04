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
      autoUpgrade.pushUpdates = true;
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
        actions = {
          enable = true;
          token = config.secrets.services.forgejo.runner-token;
        };
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
          "${config.secrets.services.forgejo.url}" = {
            useACMEHost = config.secrets.networking.primaryDomain;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://127.0.0.1:3000";
              proxyWebsockets = true;
              extraConfig = "proxy_ssl_server_name on;"; # required when the target is also TLS server with multiple hosts
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
}
