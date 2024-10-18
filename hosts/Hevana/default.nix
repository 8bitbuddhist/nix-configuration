{ config, pkgs, ... }:

let
  # Do not change this value! This tracks when NixOS was installed on your system.
  stateVersion = "24.11";
  hostName = "Hevana";

  # Where to store service files
  services-root = "/storage/services";

  # Credentials for interacting with the Namecheap API
  namecheapCredentials = {
    "NAMECHEAP_API_USER_FILE" = "${pkgs.writeText "namecheap-api-user" ''
      ${config.secrets.networking.namecheap.api.user}
    ''}";
    "NAMECHEAP_API_KEY_FILE" = "${pkgs.writeText "namecheap-api-key" ''
      ${config.secrets.networking.namecheap.api.key}
    ''}";
  };

  # List of subdomains to add to the TLS certificate
  subdomains = with config.secrets.services; [
    forgejo.url
    gremlin-lab.url
    jellyfin.url
    languagetool.url
    netdata.url
    qbittorrent.url
  ];
in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = stateVersion;
  networking.hostName = hostName;

  ###*** Configure your system below this line. ***###
  # Set your time zone.
  #   To see all available timezones, run `timedatectl list-timezones`.
  time.timeZone = "America/New_York";

  # Configure the system.
  aux.system = {
    # Enable to allow unfree (e.g. closed source) packages.
    # Some settings may override this (e.g. enabling Nvidia GPU support).
    # https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree
    allowUnfree = true;

    # Enable Secure Boot support.
    bootloader = {
      enable = true;
      secureboot.enable = true;
      tpm2.enable = true;
    };

    # Change the default text editor. Options are "emacs", "nano", or "vim".
    editor = "nano";

    # Enable GPU support.
    gpu.amd.enable = true;

    # Enable support for primary RAID array
    raid.storage = {
      enable = true;
      keyFile = config.secrets.devices.storage.keyFile.path;
      mailAddr = config.secrets.users.aires.email;
    };

    # Change how long old generations are kept for.
    retentionPeriod = "30d";

    services = {
      acme = {
        enable = true;
        defaultEmail = config.secrets.users.aires.email;
        certs = {
          "${config.secrets.networking.domains.primary}" = {
            dnsProvider = "namecheap";
            extraDomainNames = subdomains;
            webroot = null; # Required in order to prevent a failed assertion
            credentialFiles = namecheapCredentials;
          };
          "${config.secrets.networking.domains.blog}" = {
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
      autoUpgrade = {
        enable = true;
        pushUpdates = true; # Update automatically and push updates back up to Forgejo
        configDir = config.secrets.nixConfigFolder;
        onCalendar = "daily";
        user = config.users.users.aires.name;
      };
      boinc = {
        enable = false;
        home = "${services-root}/boinc";
      };
      duplicacy-web = {
        enable = true;
        home = "/storage/backups/settings/Haven";
      };
      forgejo = {
        enable = true;
        home = "${services-root}/forgejo";
        url = config.secrets.services.forgejo.url;
      };
      home-assistant = {
        enable = false;
        home = "${services-root}/home-assistant";
        url = config.secrets.services.home-assistant.url;
      };
      jellyfin = {
        enable = true;
        home = "${services-root}/jellyfin";
        url = config.secrets.services.jellyfin.url;
      };
      languagetool = {
        enable = true;
        url = config.secrets.services.languagetool.url;
        port = 8100;
        auth.user = config.secrets.services.languagetool.auth.user;
        auth.password = config.secrets.services.languagetool.auth.password;
        ngrams.enable = true;
      };
      msmtp = {
        enable = true;
        accounts.default = {
          host = config.secrets.services.msmtp.host;
          user = config.secrets.services.msmtp.user;
          password = config.secrets.services.msmtp.password;
          auth = true;
          tls = true;
          tls_starttls = true;
          port = 587;
          from = "${config.networking.hostName}@${config.secrets.networking.domains.primary}";
        };
        aliases = {
          text = ''
            default: ${config.secrets.users.aires.email}
          '';
          mode = "0644";
        };
      };
      netdata = {
        enable = true;
        type = "parent";
        url = config.secrets.services.netdata.url;
        auth = {
          user = config.users.users.aires.name;
          password = config.secrets.services.netdata.password;
          apiKey = config.secrets.services.netdata.apiKey;
        };
      };
      nginx = {
        enable = true;
        virtualHosts = {
          "${config.secrets.networking.domains.primary}" = {
            default = true;
            enableACME = true; # Enable Let's Encrypt
            locations."/" = {
              # Catchall vhost, will redirect users to Forgejo
              return = "301 https://${config.secrets.services.forgejo.url}";
            };
          };
          "${config.secrets.networking.domains.blog}" = {
            useACMEHost = config.secrets.networking.domains.blog;
            forceSSL = true;
            root = "${services-root}/nginx/sites/${config.secrets.networking.domains.blog}";
          };
          "${config.secrets.services.gremlin-lab.url}" = {
            useACMEHost = config.secrets.networking.domains.primary;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://${config.secrets.services.gremlin-lab.ip}";
              proxyWebsockets = true;
              extraConfig = "proxy_ssl_server_name on;";
            };
          };
        };
      };
      qbittorrent = {
        enable = true;
        home = "${services-root}/qbittorrent";
        url = config.secrets.services.qbittorrent.url;
        port = "8090";
        vpn = {
          enable = true;
          privateKey = config.secrets.services.protonvpn.privateKey;
          countries = [
            "Norway"
            "Netherlands"
          ];
        };
      };
      ssh = {
        enable = true;
        ports = [ config.secrets.hosts.hevana.ssh.port ];
      };
      virtualization.host = {
        enable = true;
        user = "aires";
        vmBuilds = {
          enable = true;
          cores = 3;
          ram = 4096;
        };
      };
    };

    users.aires = {
      enable = true;
      services = {
        syncthing = {
          enable = true;
          home = "${services-root}/syncthing/aires";
        };
      };
    };
  };
}
