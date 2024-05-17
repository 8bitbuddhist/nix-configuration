#!/bin/sh
# Script to unlock the /storage partition and start up services that depend on it.

# check if the current user is root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Immediately exit on any errors
set -e

# Unlock and mount storage directory if we haven't already
if [ ! -f /dev/mapper/storage ]; then
	echo "Unlocking storage partition:"
	cryptsetup luksOpen /dev/md/Sapana storage
	mount /dev/mapper/storage /storage
	echo "Storage partition mounted."
fi

#echo "Unlocking backup partition:"
# 4 TB HDD, partition #2
#cryptsetup luksOpen /dev/disk/by-uuid/8dc60329-d27c-4a4a-b76a-861b1e28400e backups --key-file /storage/backups_partition.key
#mount /dev/mapper/backups /backups
#echo "Storage and backup partitions mounted."

echo "Starting Duplicacy:"
systemctl start duplicacy-web.service
echo "Duplicacy started."

echo "Starting SyncThing:"
systemctl --machine aires@.host --user start syncthing.service
echo "SyncThing started."

exit 0
