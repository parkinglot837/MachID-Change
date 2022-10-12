#!/bin/bash

sudo cp /etc/netplan/00-installer-config.yaml ~
sudo mv /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.bak

echo "Enter new IP Address / Prefix Length: "
read ipadd
echo "Enter new Default Gateway: "
read gatewy
echo "Enter new Kubernetes IP Address / Prefix Length: "
read ipaddk
echo "Enter new Kubernetes Gateway: "
read gatewyk

sudo sed -i '5d' 00-installer-config.yaml
sudo sed -i "5i \ \ \ \ \ \ dhcp4: no" 00-installer-config.yaml
sudo sed -i "6i \ \ \ \ \ \ addresses: [$ipadd]" 00-installer-config.yaml
sudo sed -i "7i \ \ \ \ \ \ routes:" 00-installer-config.yaml
sudo sed -i "8i \ \ \ \ \ \ - to: default" 00-installer-config.yaml
sudo sed -i "9i \ \ \ \ \ \ \ \ via: $gatewy" 00-installer-config.yaml
sudo sed -i "10i \ \ \ \ \ \ nameservers:" 00-installer-config.yaml
sudo sed -i "11i \ \ \ \ \ \ \ \ addresses: [8.8.8.8,8.8.4.4]" 00-installer-config.yaml

sudo sed -i '13d' 00-installer-config.yaml
sudo sed -i "13i \ \ \ \ \ \ dhcp4: no" 00-installer-config.yaml
sudo sed -i "14i \ \ \ \ \ \ addresses: [$ipaddk]" 00-installer-config.yaml
sudo sed -i "15i \ \ \ \ \ \ routes:" 00-installer-config.yaml
sudo sed -i "16i \ \ \ \ \ \ - to: 10.0.4.0/24" 00-installer-config.yaml
sudo sed -i "17i \ \ \ \ \ \ \ \ via: $gatewyk" 00-installer-config.yaml

sudo cat 00-installer-config.yaml

echo ""
echo ""
echo "If everything looks right, press C to reset the network"

read -r -s -n 1 -p " :" key

if [ "$key" = 'C' ]; then
    echo 'Resetting network'
    sudo cp 00-installer-config.yaml /etc/netplan/00-installer-config.yaml
    sudo netplan apply
else
    echo 'Exiting script'

fi
