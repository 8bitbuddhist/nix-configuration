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
if [ -e "/dev/mapper/storage" ]; then
	echo "Storage partition already mounted."
else
	echo "Unlocking storage partition..."
	cryptsetup luksOpen /dev/md/Sapana storage
	mount /dev/mapper/storage /storage
	echo "Storage partition mounted."
fi

echo "Starting services..."
systemctl restart duplicacy-web.service
systemctl restart airsonic.service forgejo.service
systemctl --machine aires@.host --user start syncthing.service
systemctl restart nginx.service
echo "Services started. Haven is ready to go!"

exit 0
