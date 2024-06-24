{
  pkgs,
  home-manager,
  lib,
  config,
  ...
}:
let
  start-haven = pkgs.writeShellScriptBin "start-haven" (builtins.readFile ./start-haven.sh);

  services-root = "/storage/services";

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

  aux.system = {
    apps.tmux.enable = true;
    # Configure the bootloader.
    bootloader = {
      enable = true;
      secureboot.enable = true;
      tpm2.enable = true;
    };

    # Change the default text editor. Options are "emacs", "nano", or "vim".
    editor = "nano";

    gpu.amd.enable = true;

    packages = [ start-haven ];

    # Keep old generations for one month.
    retentionPeriod = "monthly";

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
          "${config.secrets.networking.blogDomain}" = {
            dnsProvider = "namecheap";
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
        home = "${services-root}/airsonic-advanced";
      };
      autoUpgrade = {
        enable = false; # Don't update the system...
        pushUpdates = true; # ...but do push updates remotely.
        configDir = config.secrets.nixConfigFolder;
        onCalendar = "daily";
        user = config.users.users.aires.name;
      };
      boinc.enable = true;
      cache = {
        enable = false; # Disable for now
        secretKeyFile = "${services-root}/nix-cache/cache-priv-key.pem";
      };
      duplicacy-web = {
        enable = true;
        autostart = false;
        environment = "/storage/backups/settings/Haven";
      };
      forgejo = {
        enable = true;
        home = "${services-root}/forgejo";
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
          "${config.secrets.networking.blogDomain}" = {
            useACMEHost = config.secrets.networking.blogDomain;
            forceSSL = true;
            root = "${services-root}/nginx/sites/${config.secrets.networking.blogDomain}";
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

  # Allow Haven to be a build target for other architectures (mainly ARM64)
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
