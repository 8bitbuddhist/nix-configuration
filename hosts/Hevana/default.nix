{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Do not change this value! This tracks when NixOS was installed on your system.
  stateVersion = "24.11";
  hostName = "Hevana";

  # Where to store service files
  services-root = "/storage/services";

  # Credentials for interacting with the Porkbun API
  porkbunCredentials = {
    "PORKBUN_API_KEY_FILE" = "${pkgs.writeText "porkbun-api-key" ''
      ${config.secrets.networking.porkbun.api.apiKey}
    ''}";
    "PORKBUN_SECRET_API_KEY_FILE" = "${pkgs.writeText "porkbun-secret-api-key" ''
      ${config.secrets.networking.porkbun.api.secretKey}
    ''}";
  };

  /*
    Add subdomains from enabled services to TLS certificate.

    This doesn't _exactly_ check for enabled services, only:
      1. Services that aren't ACME
      2. Services with an "enable" attribute.

    It still works though, so ¯\_(ツ)_/¯
  */
  serviceList = lib.attrsets.collect (
    x: x != "acme" && builtins.hasAttr "enable" x
  ) config.aux.system.services;
  subdomains = builtins.catAttrs "url" serviceList;

in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = stateVersion;
  networking.hostName = hostName;

  ###*** Configure your system below this line. ***###

  services = {
    # Enable dynamic DNS with Porkbun
    ddclient = {
      enable = true;
      configFile = pkgs.writeText "ddclient.conf" ''
        use=web, web=checkip.dyndns.com/, web-skip='IP Address'
        protocol=porkbun
        apikey=${config.secrets.networking.porkbun.api.apiKey}
        secretapikey=${config.secrets.networking.porkbun.api.secretKey}
        *.${config.secrets.networking.domains.primary},*.${config.secrets.networking.domains.blog}
        cache=/tmp/ddclient.cache
        pid=/var/run/ddclient.pid
      '';
    };

    # Monitor RAID drives using SMART
    smartd.devices = [
      { device = "/dev/sda"; }
      { device = "/dev/sdb"; }
      { device = "/dev/sdc"; }
      { device = "/dev/sdd"; }
    ];
  };

  # Build Nix packages for other hosts.
  # Runs every Saturday morning at 4 AM
  systemd.services."build-hosts" = {
    serviceConfig = {
      Type = "oneshot";
      User = "aires";
    };
    path = config.aux.system.corePackages;
    script = ''
      /run/current-system/sw/bin/nixos-operations-script --operation build --hostname Khanda --flake ${config.secrets.nixConfigFolder}
    '';
  };
  systemd.timers."build-hosts" = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sat, 04:00";
      Persistent = true;
      Unit = "build-hosts.service";
    };
  };

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
            dnsProvider = "porkbun";
            extraDomainNames = subdomains;
            webroot = null; # Required in order to prevent a failed assertion
            credentialFiles = porkbunCredentials;
          };
          "${config.secrets.networking.domains.blog}" = {
            dnsProvider = "porkbun";
            webroot = null; # Required in order to prevent a failed assertion
            credentialFiles = porkbunCredentials;
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
      binary-cache = {
        enable = true;
        secretKeyFile = "${services-root}/nixos-binary-cache/certs/cache-priv-key.pem";
        url = config.secrets.services.binary-cache.url;
        auth = {
          user = config.secrets.services.binary-cache.auth.username;
          password = config.secrets.services.binary-cache.auth.password;
        };
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
            "Switzerland"
            "Netherlands"
          ];
        };
      };
      rss = {
        enable = true;
        home = "${services-root}/freshrss";
        url = config.secrets.services.rss.url;
        auth = with config.secrets.services.rss.auth; {
          user = user;
          password = password;
        };
      };
      ssh = {
        enable = true;
        ports = [ config.secrets.hosts.hevana.ssh.port ];
      };
      syncthing = {
        enable = true;
        home = "${services-root}/syncthing/aires";
        user = "aires";
        web = {
          enable = true;
          public = true;
        };
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

    users.aires.enable = true;
  };
}
