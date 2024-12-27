# Configure basic networking options.
{ lib, ... }:
{
  networking = {
    # Default to DHCP. Set to false to use static IPs.
    useDHCP = lib.mkDefault true;

    # Enable networking via NetworkManager
    networkmanager.enable = true;

    # Enable firewall
    nftables.enable = true;
    firewall.enable = true;
  };

  # Enable fail2ban by default
  # https://github.com/fail2ban/fail2ban
  services.fail2ban.enable = true;
}
