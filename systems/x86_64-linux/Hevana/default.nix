{
  config,
  inputs,
  pkgs,
  namespace,
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
      ${config.${namespace}.secrets.networking.porkbun.api.apiKey}
    ''}";
    "PORKBUN_SECRET_API_KEY_FILE" = "${pkgs.writeText "porkbun-secret-api-key" ''
      ${config.${namespace}.secrets.networking.porkbun.api.secretKey}
    ''}";
  };

  # Block list for Nginx
  nginxBlocklist = {
    locations."/robots.txt" = {
      alias = "${inputs.ai-blocklist}/robots.txt";
    };
    extraConfig = ''
      if ($http_user_agent ~* "(${builtins.readFile "${inputs.ai-blocklist}/robots.txt"})") {
        return 444;
      }
    '';
  };
in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = stateVersion;
  networking.hostName = hostName;

  services = {
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
    path = config.${namespace}.corePackages;
    script = ''
      /run/current-system/sw/bin/nixos-operations-script --operation build --hostname Khanda --flake ${
        config.${namespace}.secrets.nixConfigFolder
      }
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
  ${namespace} = {
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
    raid = {
      enable = true;
      mailAddr = config.${namespace}.secrets.users.aires.email;
      storage = {
        enable = true;
        keyFile = config.${namespace}.secrets.devices.storage.keyFile.path;
      };
    };

    services = {
      # FIXME: Try configuring services to use Unix sockets instead of IP addresses...again
      #   https://search.nixos.org/options?channel=24.11&show=services.nginx.upstreams&query=nginx+upstream
      acme = {
        enable = true;
        defaultEmail = config.${namespace}.secrets.users.aires.email;
        certs = {
          "${config.${namespace}.secrets.networking.domains.primary}" = {
            dnsProvider = "porkbun";
            domain = "*.${config.${namespace}.secrets.networking.domains.primary}";
            webroot = null; # Required in order to prevent a failed assertion
            credentialFiles = porkbunCredentials;
          };
          "${config.${namespace}.secrets.networking.domains.blog}" = {
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
      archiveteam-warrior = {
        enable = true;
        useVPN = true;
        home = "${services-root}/archiveteam-warrior";
        port = 8001;
        config.${namespace}.secrets.users.common.sshConfig."hevana".localForwards =
          with config.${namespace}.services.archiveteam-warrior; [
            {
              bind.port = port;
              host.port = port;
            }
          ];
      };
      autoUpgrade = {
        enable = true;
        pushUpdates = true; # Update automatically and push updates back up to Forgejo
        configDir = config.${namespace}.secrets.nixConfigFolder;
        onCalendar = "daily";
        user = config.users.users.aires.name;
      };
      binary-cache = {
        enable = true;
        secretKeyFile = "${services-root}/nixos-binary-cache/certs/cache-priv-key.pem";
        url = config.${namespace}.secrets.services.binary-cache.url;
        auth = {
          user = config.${namespace}.secrets.services.binary-cache.auth.username;
          password = config.${namespace}.secrets.services.binary-cache.auth.password;
        };
      };
      duplicacy-web = {
        enable = true;
        home = "/storage/backups/settings/Haven";
        config.${namespace}.secrets.users.common.sshConfig."hevana".localForwards =
          with config.${namespace}.services.duplicacy-web; [
            {
              bind.port = port;
              host.port = port;
            }
          ];
      };
      forgejo = {
        enable = true;
        home = "${services-root}/forgejo";
        url = config.${namespace}.secrets.services.forgejo.url;
      };
      jellyfin = {
        enable = true;
        home = "${services-root}/jellyfin";
        url = config.${namespace}.secrets.services.jellyfin.url;
      };
      languagetool = {
        enable = true;
        url = config.${namespace}.secrets.services.languagetool.url;
        port = 8100;
        auth = {
          user = config.${namespace}.secrets.services.languagetool.auth.user;
          password = config.${namespace}.secrets.services.languagetool.auth.password;
        };
        ngrams.enable = true;
      };
      msmtp = {
        enable = true;
        accounts.default = {
          host = config.${namespace}.secrets.services.msmtp.host;
          user = config.${namespace}.secrets.services.msmtp.user;
          password = config.${namespace}.secrets.services.msmtp.password;
          auth = true;
          tls = true;
          tls_starttls = true;
          port = 587;
          from = "${config.networking.hostName}@${config.${namespace}.secrets.networking.domains.primary}";
        };
        aliases = {
          text = ''
            default: ${config.${namespace}.secrets.users.aires.email}
          '';
          mode = "0644";
        };
      };
      netdata = {
        enable = false;
        type = "parent";
        url = config.${namespace}.secrets.services.netdata.url;
        auth = {
          user = config.users.users.aires.name;
          password = config.${namespace}.secrets.services.netdata.password;
          apiKey = config.${namespace}.secrets.services.netdata.apiKey;
        };
      };
      nginx = {
        enable = true;
        virtualHosts = {
          "${config.${namespace}.secrets.networking.domains.primary}" = {
            default = true;
            enableACME = true; # Enable Let's Encrypt
            locations."/" = {
              # Catchall vhost, will redirect users to Forgejo
              return = "301 https://${config.${namespace}.secrets.services.forgejo.url}";
            };
          } // nginxBlocklist;
          # Personal blog website
          "${config.${namespace}.secrets.networking.domains.blog}" = {
            useACMEHost = config.${namespace}.secrets.networking.domains.blog;
            forceSSL = true;
            root = "${services-root}/nginx/sites/${config.${namespace}.secrets.networking.domains.blog}";
          } // nginxBlocklist;
          # Work lab VM
          "${config.${namespace}.secrets.hosts.gremlin-lab.URI}" = {
            useACMEHost = config.${namespace}.secrets.networking.domains.primary;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://${config.${namespace}.secrets.hosts.gremlin-lab.IP}";
              proxyWebsockets = true;
              extraConfig = "proxy_ssl_server_name on;";
            };
          };
        };
      };
      open-webui = {
        #home = "${services-root}/open-webui";
        enable = true;
        url = config.${namespace}.secrets.services.open-webui.url;
        ollama.enable = true;
      };
      qbittorrent = {
        enable = true;
        home = "${services-root}/qbittorrent";
        url = config.${namespace}.secrets.services.qbittorrent.url;
        port = 8090;
      };
      ssh = {
        enable = true;
        ports = [ config.${namespace}.secrets.hosts.hevana.ssh.port ];
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
      tor = {
        enable = true;
        snowflake-proxy = {
          enable = true;
          capacity = 50;
        };
      };
      virtualization.host = {
        enable = true;
        vmBuilds = {
          enable = true;
          cores = 3;
          ram = 4096;
        };
      };
      vpn = {
        enable = true;
        privateKey = config.${namespace}.secrets.services.protonvpn.privateKey;
        countries = [
          "Switzerland"
          "Netherlands"
        ];
        port = config.${namespace}.services.qbittorrent.port;
      };
    };

    users.aires.enable = true;
  };
}
