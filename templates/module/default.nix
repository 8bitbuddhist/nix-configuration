# This is an example of a blank module.
{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.myModule;
in
{
  options = {
    ${namespace}.services.myModule = {
      enable = lib.mkEnableOption "Enables this example module.";
      attributes = lib.mkOption {
        default = { };
        type = lib.types.attrs;
        description = "An example of an attributes option.";
      };
      string = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "An example of a string option.";
      };
      list = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.int;
        description = "An example of a list (of integers) option.";
      };
      enum = lib.mkOption {
        default = "one";
        type = lib.types.enum [
          "one"
          "two"
        ];
        description = "An example of an enum option.";
      };
    };

  };

  config = lib.mkIf cfg.enable {
    # Define the changes applied by this module here.
  };

  systemd.services = {
    # Tell systemd to wait for the module's configuration directory to be available before starting the service.
    myModule.unitConfig.RequiresMountsFor = cfg.home;

    # Tell Nginx to wait for the service to be available before coming online.
    nginx.wants = [ config.systemd.services.myModule.name ];
  };
}
