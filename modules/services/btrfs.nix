# Services to run on BTRFS filesystems.
# Only run if the root partition is BTRFS.
{ config, lib, ... }:
{
  services.btrfs.autoScrub = lib.mkIf (config.fileSystems."/".fsType == "btrfs") {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };
}
