#!/bin/sh
# Script to unlock the /storage partition and start up services that depend on it.

# check if the current user is root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Immediately exit on any errors
set -e

echo "Unlocking storage partition:"
# RAID 5
cryptsetup luksOpen /dev/md/Sapana storage

# mount local storage
if [ ! -f /dev/mapper/storage ]; then
    mount /dev/mapper/storage /storage

    if [ $? -eq "0" ]; then
		echo "Unlocking backup partition:"
		# 4 TB HDD, partition #2
		cryptsetup luksOpen /dev/disk/by-uuid/8dc60329-d27c-4a4a-b76a-861b1e28400e backups --key-file /storage/backups_partition.key
		mount /dev/mapper/backups /backups

		echo "Storage and backup partitions mounted."

		echo "Starting Duplicacy:"
		systemctl start duplicacy-web.service
		if [ $? -eq "0" ]; then
			echo "Duplicacy started."
		else
			echo "Failed to start Duplicacy."
		fi

		echo "Starting SyncThing:"
		systemctl --machine aires@.host --user start syncthing.service
		if [ $? -eq "0" ]; then
			echo "SyncThing started."
		else
			echo "Failed to start SyncThing."
		fi
	else
		echo "Failed to mount storage partition."
	fi
else
	echo "Failed to unlock storage and/or backup partition(s)."
fi

exit 0
