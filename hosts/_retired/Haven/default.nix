{ pkgs, config, ... }:
let
  stateVersion = "24.05";
  hostName = "Haven";

  start-haven = pkgs.writeShellScriptBin "start-haven" (builtins.readFile ./start-haven.sh);

  services-root = "/storage/services";

  subdomains = [
    config.secrets.services.airsonic.url
    config.secrets.services.cache.url
    config.secrets.services.forgejo.url
    config.secrets.services.gremlin-lab.url
  ];

  namecheapCredentials = {
    "NAMECHEAP_API_USER_FILE" = "${pkgs.writeText "namecheap-api-user" ''
      ${config.secrets.networking.namecheap.api.user}
    ''}";
    "NAMECHEAP_API_KEY_FILE" = "${pkgs.writeText "namecheap-api-key" ''
      ${config.secrets.networking.namecheap.api.key}
    ''}";
  };
in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = stateVersion;
  networking.hostName = hostName;

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

    packages = [
      start-haven
      pkgs.htop
    ];

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
            credentialFiles = namecheapCredentials;
          };
          "${config.secrets.networking.blogDomain}" = {
            dnsProvider = "namecheap";
            webroot = null; # Required in order to prevent a failed assertion
            credentialFiles = namecheapCredentials;
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
        domain = config.secrets.networking.primaryDomain;
        url = config.secrets.services.airsonic.url;
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
        domain = config.secrets.networking.primaryDomain;
        url = config.secrets.services.forgejo.url;
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
        };
      };
      ssh = {
        enable = true;
        ports = [ config.secrets.hosts.haven.ssh.port ];
      };
      virtualization = {
        host = {
          enable = true;
          user = "aires";
          vmBuilds = {
            enable = true;
            cores = 3;
            ram = 4096;
          };
        };
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

  # Allow Haven to be a build target for other architectures (mainly ARM64)
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
