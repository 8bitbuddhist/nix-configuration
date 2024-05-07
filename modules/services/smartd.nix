# Configure SMART monitoring
_: {
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.wall.enable = true;
  };
}
