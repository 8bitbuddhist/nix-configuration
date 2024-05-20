{
  pkgs,
  home-manager,
  lib,
  config,
  ...
}:
let
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
      airsonic = {
        enable = true;
        domain = config.secrets.networking.primaryDomain;
        home = "/storage/services/airsonic-advanced";
      };
      duplicacy-web = {
        enable = true;
        autostart = false;
        environment = "${config.users.users.aires.home}";
      };
      forgejo = {
        enable = true;
        domain = config.secrets.networking.primaryDomain;
        home = "/storage/services/forgejo";
      };
      msmtp.enable = true;
    };
    users = {
      aires = {
        enable = true;
        services.syncthing = {
          enable = true;
          autostart = false;
        };
      };
      media.enable = true;
    };
  };

  # TLS certificate renewal via Let's Encrypt
  security.acme = {
    acceptTerms = true;
    defaults.email = "${config.secrets.users.aires.email}";

    certs."${config.secrets.networking.primaryDomain}" = {
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
  # /var/lib/acme/.challenges must be writable by the ACME user
  # and readable by the Nginx user. The easiest way to achieve
  # this is to add the Nginx user to the ACME group.
  users.users.nginx.extraGroups = [ "acme" ];

  services = {
    nginx = {
      enable = true;

      # Use recommended settings per https://nixos.wiki/wiki/Nginx#Hardened_setup_with_TLS_and_HSTS_preloading
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;

      virtualHosts = {
        # Base URL: make sure we've got Let's Encrypt running challenges here, and all other requests going to HTTPS
        "${config.secrets.networking.primaryDomain}" = {
          default = true;
          enableACME = true;
          # Catchall vhost, will Redirect users to Forgejo
          locations."/" = {
            return = "301 https://code.${config.secrets.networking.primaryDomain}";
          };
        };
      };
    };

    # Enable BOINC (distributed research computing)
    boinc = {
      enable = true;
      package = pkgs.boinc-headless;
      dataDir = "/var/lib/boinc";
      extraEnvPackages = [ pkgs.ocl-icd ];
    };

    # Enable SSH
    openssh = {
      enable = true;
      ports = [ config.secrets.hosts.haven.ssh.port ];

      settings = {
        # require public key authentication and disable root logins
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PubkeyAuthentication = true;
        PermitRootLogin = "no";
      };
    };

    # TODO: VPN (Check out Wireguard)
  };

  # Nginx: Disable autostart, and start sub-services first.
  systemd.services.nginx.wantedBy = lib.mkForce [ ];

  # Open ports
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80
      443
    ];
  };

  # Add Haven's startup script
  environment.systemPackages = [ start-haven ];

  # Allow Haven to be a build target for other architectures (mainly ARM64)
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
