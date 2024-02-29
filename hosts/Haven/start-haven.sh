#!/bin/sh
# Script to unlock the /storage partition and start up services that depend on it.

# check if the current user is root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Immediately exit on any errors
set -e

# local storage partition
echo "Unlocking storage partition:"
cryptsetup luksOpen /dev/disk/by-uuid/223582c7-fbad-467d-8f85-4d4cebd3230c storage

# mount local storage
if [ ! -f /dev/mapper/storage ]; then
    mount /dev/mapper/storage /storage

    if [ $? -eq "0" ]; then
		echo "Storage and backup partitions mounted."

		echo "Starting Duplicacy:"
		systemctl start duplicacy-web.service
		if [ $? -eq "0" ]; then
			echo "Duplicacy started."
		else
			echo "Failed to start Duplicacy."
		fi

		echo "Starting SyncThing:"
		systemctl --user -M aires@ start syncthing.service
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