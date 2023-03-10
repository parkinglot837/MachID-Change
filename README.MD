# Introduction:
Updated: 2022-10-11

These scripts provide a way to change the MachineID, Hostname, IP Addresses (static), and Server SSH keys for a Cloned Ubuntu server.
This was tested on VirtualBox.

# Background:
A cloned Ubuntu server (on VirtualBox) does not get a new MachineID.
The MachineID is found in 2 locations:
    /etc/machine-id
    /var/lib/dbus/machine-id
This caused an issue when using DHCP.  The cloned server would pick up the same IP as the original server.  And it seemed like an interesting little problem to solve.

# Prerequisites:
Ubuntu LTS 22.04 Minimal install.
Add any other basic tool packages; wget, curl, net tools, nano, vim, etc.
Logged-in User account should have sudo privileges.

# Instuctions:
1. Download all scripts and service files into home directory
2. Run the InitializeMachID.sh


# Files:
* InitializeMachID.sh
* netchange.sh
* regenerateSSH.sh
* regeneratekey.service

This is the end.
