#!/usr/bin/env bash
# ==============================================================================
# Script: create-ubuntu24-template.sh
# Description: Automatically downloads Ubuntu 24.04 LTS Cloud Image, configures
#              Cloud-Init, sets user/password/sudo, and creates Proxmox Template.
# Run on: Proxmox VE Host shell (as root)
# ==============================================================================

set -euo pipefail

# Configuration Defaults (Override via environment variables if desired)
VM_ID="${VM_ID:-9000}"
VM_NAME="${VM_NAME:-ubuntu-2404-cloudinit-template}"
STORAGE="${STORAGE:-local-lvm}"
DISK_SIZE="${DISK_SIZE:-30G}"
BRIDGE="${BRIDGE:-vmbr0}"
MEMORY="${MEMORY:-2048}"
CORES="${CORES:-2}"
CI_USER="${CI_USER:-ubadmin}"
CI_PASSWORD="${CI_PASSWORD:-ubadmin}"
UBUNTU_RELEASE="noble" # Ubuntu 24.04 LTS
IMAGE_NAME="ubuntu-24.04-server-cloudimg-amd64.img"
IMAGE_URL="https://cloud-images.ubuntu.com/releases/24.04/release/${IMAGE_NAME}"

echo "======================================================================"
echo "  Proxmox VE: Ubuntu 24.04 LTS Cloud-Init Template Generator"
echo "======================================================================"

# Check if running on Proxmox VE
if ! command -v qm &> /dev/null; then
    echo "Error: This script must be run on a Proxmox VE host ('qm' command not found)."
    exit 1
fi

# Check if VM_ID already exists
if qm status "$VM_ID" &> /dev/null; then
    echo "Error: VM ID $VM_ID already exists. Choose a different VM_ID or destroy existing VM."
    exit 1
fi

# Step 1: Download Ubuntu 24.04 Cloud Image
echo "==> Downloading Ubuntu 24.04 LTS Cloud Image..."
if [ ! -f "/tmp/${IMAGE_NAME}" ]; then
    wget -O "/tmp/${IMAGE_NAME}" "$IMAGE_URL"
else
    echo "    Image already cached at /tmp/${IMAGE_NAME}"
fi

# Step 2: Install qemu-guest-agent package into image (optional but recommended)
echo "==> Customizing image with qemu-guest-agent support..."
if command -v virt-customize &> /dev/null; then
    virt-customize -a "/tmp/${IMAGE_NAME}" --install qemu-guest-agent
else
    echo "    (virt-customize not installed, skipping pre-installation of qemu-guest-agent)"
fi

# Step 3: Create Proxmox VM shell
echo "==> Creating VM $VM_ID ($VM_NAME)..."
qm create "$VM_ID" \
    --name "$VM_NAME" \
    --memory "$MEMORY" \
    --cores "$CORES" \
    --net0 "virtio,bridge=${BRIDGE}" \
    --ostype l26 \
    --agent enabled=1

# Step 4: Import Cloud Disk to Proxmox Storage & Resize
echo "==> Importing disk to $STORAGE and expanding to $DISK_SIZE..."
qm set "$VM_ID" --scsihw virtio-scsi-pci
qm set "$VM_ID" --scsi0 "${STORAGE}:0,import-from=/tmp/${IMAGE_NAME}"
qm disk resize "$VM_ID" scsi0 "$DISK_SIZE"

# Step 5: Add Cloud-Init drive, set user/password with sudo, & configure boot settings
echo "==> Configuring Cloud-Init drive, user '$CI_USER' with sudo, and boot order..."
qm set "$VM_ID" --ide2 "${STORAGE}:cloudinit"
qm set "$VM_ID" --ciuser "$CI_USER" --cipassword "$CI_PASSWORD"
qm set "$VM_ID" --boot c --bootdisk scsi0
qm set "$VM_ID" --serial0 socket --vga serial0

# Step 6: Convert to Proxmox Template
echo "==> Converting VM $VM_ID to Template..."
qm template "$VM_ID"

echo "======================================================================"
echo " [✓] Ubuntu 24.04 LTS Template (ID: $VM_ID) created successfully!"
echo "======================================================================"
echo " Default Credentials & Sudo Access:"
echo "   Username: $CI_USER"
echo "   Password: $CI_PASSWORD"
echo "   Sudo:     Full sudo access enabled"
echo "======================================================================"
echo "You can now clone this template to deploy new VMs instantly:"
echo ""
echo "  # 1. Clone template to target storage (e.g., proxlake):"
echo "  qm clone $VM_ID 101 --name my-ubuntu-vm --storage proxlake --full"
echo ""
echo "  # 2. (Optional) Resize disk for this specific VM (e.g. to 50G):"
echo "  qm disk resize 101 scsi0 50G"
echo ""
echo "  # 3. Configure network and SSH keys:"
echo "  qm set 101 --ipconfig0 ip=192.168.1.50/24,gw=192.168.1.1"
echo "  qm set 101 --sshkeys ~/.ssh/id_rsa.pub"
echo "  qm start 101"
echo ""
