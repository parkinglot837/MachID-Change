#!/bin/bash
# Change network

echo Change network to static IP Addresses
. netchange.sh

# changes hostname
echo Enter New Hostname:
read myhstnm
sudo hostnamectl set-hostname $myhstnm

# updates /etc/hosts file with hostname
echo 'Update /etc/hosts file with new hostname'
sudo sed -i '2d' /etc/hosts
sudo sed -i "2i 127.0.1.1 $myhstnm" /etc/hosts

# Clears out machine-ID, so that the OS can pick a new one after the next reboot.
sudo truncate -s 0 /etc/machine-id
machID=$(cat /etc/machine-id)
echo "Is the etc machine ID Blanked?: $machID  <-- should be blank"
sudo truncate -s 0 /var/lib/dbus/machine-id
dbmachID=$(cat /var/lib/dbus/machine-id)
echo "Is the dbus machine ID Blanked?: $dbmachID  <-- should be blank"
echo "If either etc or dbus machine IDs are not blank - Stop the Script and manual delete these manually"
echo "located at /etc/machine-id  and  /var/lib/dbus/machine-id "
echo "   Afterwards run the script -- ./regenerateSSH.sh "
echo " "
echo "Press 'c' to proceed to re-issue SSH Public and Private Host Key."
echo "OR Any other key to stop this script…"
read -r -s -n 1 -p " :" key

if [ "$key" = 'c' ]; then
    echo 'Re-issue keys'
    . regenerateSSH.sh
    # echo [$key] is empty when SPACE is pressed # uncomment to trace
else
    echo 'Exiting script'
    # Anything else pressed, do whatever else.
    # echo [$key] not empty
fi
