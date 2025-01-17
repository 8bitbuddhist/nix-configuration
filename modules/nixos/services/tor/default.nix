# https://wiki.nixos.org/wiki/Tor
{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.tor;
in
{
  options = {
    ${namespace}.services.tor = {
      enable = lib.mkEnableOption "Enables the TOR router.";
      browser.enable = lib.mkEnableOption "Installs the TOR browser.";
      relay = {
        enable = lib.mkEnableOption "Configures the system as a TOR relay.";
        role = lib.mkOption {
          description = "Whether to treat this as a regular relay or a bridge.";
          default = "relay";
          type = lib.types.enum [
            "relay"
            "bridge"
          ];
        };
        ORPort = lib.mkOption {
          type = lib.types.str;
          description = "The port (or IP:port) to bind the Tor relay to.";
        };
      };
      # For details, see https://wiki.nixos.org/wiki/Tor#Advanced
      settings = lib.mkOption {
        description = "Settings to apply to the relay.";
        type = lib.types.attrs;
        default = {
          # Reject all exit traffic
          ExitPolicy = [ "reject *:*" ];

          # Performance and security settings
          CookieAuthentication = true;
          AvoidDiskWrites = 1;
          HardwareAccel = 1;
          SafeLogging = 1;
        };
      };
      snowflake-proxy = {
        enable = lib.mkEnableOption "Enables Snowflake Proxy. See https://snowflake.torproject.org.";
        capacity = lib.mkOption {
          type = lib.types.int;
          default = 10;
          description = "How many concurrent clients to support.";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.tor = {
        enable = true;
        settings = cfg.settings;
      };

      services.snowflake-proxy = lib.mkIf cfg.snowflake-proxy.enable {
        enable = true;
        capacity = cfg.snowflake-proxy.capacity;
      };
    })
    (lib.mkIf cfg.browser.enable {
      services.tor = {
        client.enable = true;

        # Enable Torsocks for transparent proxying of applications through Tor
        torsocks.enable = true;
      };

      ${namespace}.ui.flatpak.packages = [
        "org.torproject.torbrowser-launcher"
      ];
    })
    (lib.mkIf cfg.relay.enable {
      services.tor.relay = {
        enable = true;
        role = cfg.relay.role;
      };
    })
  ];
}
