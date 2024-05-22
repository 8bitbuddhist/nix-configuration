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
        domain = config.secrets.networking.primaryDomain;
        home = "/storage/services/airsonic-advanced";
      };
      boinc.enable = true;
      duplicacy-web = {
        enable = true;
        autostart = false;
        environment = "/storage/backups/settings/Haven";
      };
      forgejo = {
        enable = true;
        domain = config.secrets.networking.primaryDomain;
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
              return = "301 https://code.${config.secrets.networking.primaryDomain}";
            };
          };
        };
      };
      ssh = {
        enable = true;
        ports = [ config.secrets.hosts.haven.ssh.port ];
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
