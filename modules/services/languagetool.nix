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
      ngrams.enable = lib.mkEnableOption (
        lib.mdDoc "Enables n-gram data set. See https://dev.languagetool.org/finding-errors-using-n-gram-data.html"
      );
      domain = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The root domain that LanguageTool will be hosted on.";
        example = "example.com";
      };
      password = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The password to use for basic authentication for LanguageTool.";
        example = "MySuperSecurePassword123";
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
        port = 8090;
        public = true;
        allowOrigin = "*";
        # Enable Ngrams
        settings.languageModel = lib.mkIf cfg.ngrams.enable "${
          (pkgs.callPackage ../../packages/languagetool-ngrams.nix { inherit pkgs lib; })
        }/ngrams";
      };
      # Create Nginx virtualhost
      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = cfg.domain;
        forceSSL = true;
        basicAuth = {
          ltuser = cfg.password;
        };
        locations."/" = {
          proxyPass = "http://127.0.0.1:8090";
          extraConfig = "proxy_ssl_server_name on;";
        };
      };
    };

    systemd.services.nginx.wants = [ config.systemd.services.languagetool.name ];
  };
}
