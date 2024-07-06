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
}
