{
  pkgs,
  home-manager,
  lib,
  config,
  ...
}:
let
  cfg = config.services.forgejo;
  forgejo-cli = pkgs.writeScriptBin "forgejo-cli" ''
    #!${pkgs.runtimeShell}
    cd ${cfg.stateDir}
    sudo=exec
    if [[ "$USER" != forgejo ]]; then
      sudo='exec /run/wrappers/bin/sudo -u ${cfg.user} -g ${cfg.group} --preserve-env=GITEA_WORK_DIR --preserve-env=GITEA_CUSTOM'
    fi
    # Note that these variable names will change
    export GITEA_WORK_DIR=${cfg.stateDir}
    export GITEA_CUSTOM=${cfg.customDir}
    $sudo ${lib.getExe cfg.package} "$@"
  '';
  start-haven = pkgs.writeShellScriptBin "start-haven" (builtins.readFile ./start-haven.sh);

  subdomains = map (subdomain: subdomain + ".${config.secrets.networking.primaryDomain}") [
    "code"
    "music"
  ];
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

  # TLS certificate renewal via Let's Encrypt
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "${config.secrets.users.aires.email}";
    };

    certs."${config.secrets.networking.primaryDomain}" = {
      dnsProvider = "namecheap";
      extraDomainNames = subdomains;
      webroot = null; # Prevents an assertion error
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
  # /var/lib/acme/.challenges must be writable by the ACME user
  # and readable by the Nginx user. The easiest way to achieve
  # this is to add the Nginx user to the ACME group.
  users.users.nginx.extraGroups = [ "acme" ];
  users.users.airsonic.extraGroups = [ "media" ];

  services = {
    nginx = {
      enable = true;

      # Use recommended settings per https://nixos.wiki/wiki/Nginx#Hardened_setup_with_TLS_and_HSTS_preloading
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      #recommendedProxySettings = true; # Recommended settings break Airsonic
      recommendedTlsSettings = true;

      virtualHosts = {
        # Base URL: make sure we've got Let's Encrypt running challenges here, and all other requests going to HTTPS
        "${config.secrets.networking.primaryDomain}" = {
          # Catchall vhost, will redirect users to HTTPS for all vhosts
          default = true;
          enableACME = true;
          #serverAliases = subdomains;
          locations."/" = {
            return = "301 https://$host$request_uri";
          };
        };

        # Forgejo
        "code.${config.secrets.networking.primaryDomain}" = {
          useACMEHost = "${config.secrets.networking.primaryDomain}";
          forceSSL = true;
          listen = [
            {
              port = 443;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
            proxyWebsockets = true; # needed if you need to use WebSocket
            extraConfig =
              # required when the target is also TLS server with multiple hosts
              "proxy_ssl_server_name on;";
          };
        };

        # Airsonic
        "music.${config.secrets.networking.primaryDomain}" = {
          useACMEHost = "${config.secrets.networking.primaryDomain}";
          forceSSL = true;
          listen = [
            {
              port = 443;
              addr = "0.0.0.0";
              ssl = true;
            }
          ];
          locations."/" = {
            proxyPass = "http://127.0.0.1:4040";
            proxyWebsockets = true; # needed if you need to use WebSocket
          };
        };
      };
    };

    # Enable Airsonic-Advanced (music streaming)
    airsonic = {
      enable = true;
      war = "${
        (pkgs.callPackage ../../packages/airsonic-advanced.nix { inherit lib; })
      }/webapps/airsonic-advanced.war";
      port = 4040;
      jre = pkgs.jdk17_headless;
      jvmOptions = [
        "-Dserver.use-forward-headers=true"
        "-Xmx4G"
      ];
      home = "/storage/services/airsonic-advanced";
    };

    # Enable BOINC (distributed research computing)
    boinc = {
      enable = true;
      package = pkgs.boinc-headless;
      dataDir = "/var/lib/boinc";
      extraEnvPackages = [ pkgs.ocl-icd ];
    };

    # Enable Forgejo / Gitea (code repository)
    forgejo = {
      enable = true;
      stateDir = "/storage/services/forgejo";
      # Enable support for Git Large File Storage
      lfs.enable = true;
      settings = {
        server = {
          DOMAIN = "${config.secrets.networking.primaryDomain}";
          ROOT_URL = "https://code.${config.secrets.networking.primaryDomain}/";
          HTTP_PORT = 3000;
          /*
          DISABLE_SSH = false;
          SSH_PORT = config.secrets.services.forgejo.sshPort;
          START_SSH_SERVER = true;
          BUILTIN_SSH_SERVER_USER = "forgejo";
          */
        };
      };
      useWizard = true;
    };

    # Enable SSH
    openssh = {
      enable = true;
      ports = [ config.secrets.hosts.haven.ssh.port ];

      settings = {
        # require public key authentication for better security
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PubkeyAuthentication = true;

        PermitRootLogin = "without-password";
      };
    };

    # TODO: VPN (Check out Wireguard)
  };

  # Configure services
  systemd.services = {
    # Airsonic: Disable autostart and set environment variables. Started via start-haven script
    airsonic = {
      wantedBy = lib.mkForce [ ];
    };

    # Foregejo: Disable autostart. Started via start-haven script
    forgejo = {
      wantedBy = lib.mkForce [ ];
    };

    # Nginx: Disable autostart. Started via start-haven script
    nginx = {
      wantedBy = lib.mkForce [ ];
      wants = [
        "airsonic.service"
        "forgejo.service"
      ];
    };
  };

  # Open ports
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80
      443
      22222
    ];
  };

  # Add extra packages:
  # 1: forgejo CLI tool
  # 2: Haven's startup script
  environment.systemPackages = [
    forgejo-cli
    start-haven
  ];

  # Allow Haven to be a build target for other architectures (mainly ARM64)
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
