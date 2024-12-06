{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.aux.system.services.languagetool;
in
{
  options = {
    aux.system.services.languagetool = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables LanguageTool server.");
      auth = {
        password = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "The password to use for basic authentication for LanguageTool.";
          example = "MySuperSecurePassword123";
        };
        user = lib.mkOption {
          default = "ltuser";
          type = lib.types.str;
          description = "The username to use for basic auth.";
        };
      };
      ngrams.enable = lib.mkEnableOption (
        lib.mdDoc "Enables n-gram data set. See https://dev.languagetool.org/finding-errors-using-n-gram-data.html"
      );
      port = lib.mkOption {
        default = 8080;
        type = lib.types.int;
        description = "The port to run LanguageTool on.";
        example = 8080;
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where LanguageTool is hosted.";
        example = "https://languagetool.example.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      languagetool = lib.mkIf cfg.enable {
        enable = true;
        port = cfg.port;
        public = true;
        allowOrigin = "*";
        # Enable Ngrams
        settings.languageModel = lib.mkIf cfg.ngrams.enable "${pkgs.Sapana.languagetool-ngrams}/share/languagetool/ngrams";
      };
      # Create Nginx virtualhost
      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = lib.Sapana.getDomainFromURI cfg.url;
        forceSSL = true;
        basicAuth = {
          "${cfg.auth.user}" = cfg.auth.password;
        };
        locations."/" = {
          proxyPass = "http://127.0.0.1:${builtins.toString cfg.port}";
          extraConfig = "proxy_ssl_server_name on;";
        };
      };
    };

    systemd.services.nginx.wants = [ config.systemd.services.languagetool.name ];
  };
}
