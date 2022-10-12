#!/bin/bash

echo "Regenerating SSH Keys"
# regenerate Server SSH Pub / Private Keys on next boot

sudo rm /etc/ssh/ssh_host_*
sudo mv ~/regeneratekey.service /etc/systemd/system/regeneratekey.service
sudo chown root:root /etc/systemd/system/regeneratekey.service
sudo chmod 644 /etc/systemd/system/regeneratekey.service

sudo systemctl enable regeneratekey.service
systemctl status regeneratekey.service

echo ' '
echo ' Regeneratekey Service will be enabled on the next Reboot '
# Clean up home dir
echo "Cleaning up home directory"
sudo rm ~/*.service
sudo rm ~/*.sh
sudo rm 
# sudo cp ~/.kubinstall/kube-install.sh ~/kube-install1.sh
# chmod 764 ~/kube-install1.sh
sleep 5s

# Reboot to have all changes take effect
    read -r -s -p $'Press Enter to Reboot...'
    sudo -S reboot

else
    echo 'Exiting Script'
fi