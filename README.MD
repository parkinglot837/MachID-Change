# Ubuntu 24.04 LTS VM Deployment on Proxmox VE (Cloud-Init)

This repository provides instructions and automation to streamline the rapid deployment of **Ubuntu 24.04 LTS (Noble Numbat)** VMs on **Proxmox VE** using **Cloud-Init**.

---

## 🚀 Why Cloud-Init?

With Proxmox VE native **Cloud-Init** support, legacy post-clone interactive scripts (manual machine-id blanking, netplan YAML editing, and SSH host key regeneration) are obsolete.

Cloud-Init automatically performs the following during the initial VM boot:
- 🆔 **Unique Machine ID**: Systemd generates a brand-new, unique `/etc/machine-id` on first boot.
- 🔑 **Unique SSH Host Keys**: OpenSSH host keys (`/etc/ssh/ssh_host_*`) are regenerated automatically.
- 🌐 **Network & Static IPs**: IP address, subnet mask, default gateway, and DNS servers are configured automatically based on Proxmox settings.
- 🖥️ **Hostname**: Set dynamically from Proxmox VM name or CLI flags.
- 🗝️ **SSH Authorized Keys**: Injects your public SSH key into the default user account.
- 💾 **Auto-Expanding Filesystem**: `cloud-init` / `systemd-growfs` automatically expands Ubuntu's root filesystem (`/`) to fit the allocated disk size upon first boot!

---

## 🛠️ Method 1: Automated Template Creation (Recommended)

Run [create-ubuntu24-template.sh](file:///Users/s.park/f5-demos/MachID-Change/create-ubuntu24-template.sh) on your **Proxmox VE host shell** (as `root`):

```bash
# Clone or copy this repo to your Proxmox host, then run:
chmod +x create-ubuntu24-template.sh
sudo ./create-ubuntu24-template.sh
```

### Customizing Template Defaults (Optional):
You can override default settings using environment variables:

```bash
VM_ID=9000 VM_NAME="ubuntu-2404-template" STORAGE="local-lvm" DISK_SIZE="30G" ./create-ubuntu24-template.sh
```

---

## 📋 Method 2: Manual Proxmox CLI Step-by-Step

If you prefer setting up the template manually on your Proxmox host:

```bash
# 1. Download official Ubuntu 24.04 LTS Minimal Cloud Image
wget https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img -O /tmp/ubuntu-24.04.img

# 2. Create VM shell (VM ID 9000)
qm create 9000 --name ubuntu-2404-cloudinit-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0 --agent enabled=1

# 3. Import cloud disk to storage (e.g., local-lvm)
qm set 9000 --scsihw virtio-scsi-pci
qm set 9000 --scsi0 local-lvm:0,import-from=/tmp/ubuntu-24.04.img

# 4. Attach Cloud-Init drive & set boot device
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0

# 5. Set default Template disk size (e.g., expand from 3.5GB to 30GB)
qm disk resize 9000 scsi0 30G

# 6. Convert VM to Template
qm template 9000
```

---

## 💽 Disk Sizing & Resizing Guide

The default Ubuntu Cloud image comes with a ~3.5 GB disk. You can set the disk size in **two ways**:

### Option A: Set Base Disk Size on the Template (Applies to all clones)
Resize the template's disk before or after converting to a template. All cloned VMs will inherit this base size (e.g., 30 GB):
```bash
qm disk resize 9000 scsi0 30G
```

### Option B: Resize Disk on a Specific Cloned VM (Per-VM size)
If different VMs require different disk sizes (e.g., VM 101 needs 50 GB), resize the VM's `scsi0` disk after cloning:

- **CLI**:
  ```bash
  qm disk resize 101 scsi0 50G
  ```
- **Web GUI**:
  Select VM `101` -> **Hardware** -> click **Hard Disk (scsi0)** -> click **Disk Action** -> **Resize** -> enter additional size (e.g. `20` for +20 GB).

> 💡 **Auto-Growth Feature**: When the VM boots up for the first time, Ubuntu 24.04's `cloud-init` automatically resizes the root partition and filesystem to 100% of the allocated disk space. No manual partition editing inside Linux is needed!

---

## ⚡ Deploying a New VM in Seconds

Once your template is created, deploy and customize new Ubuntu 24.04 VMs using either **Proxmox CLI** or the **Proxmox Web GUI**.

### 💾 Specifying Target Storage (`proxlake`) & Disk Size

#### Option A: Proxmox CLI (`qm` commands)

```bash
# 1. Clone template (ID 9000) to new VM (ID 101) on storage 'proxlake'
qm clone 9000 101 --name k8s-node-01 --storage proxlake --full

# 2. (Optional) Resize disk specifically for VM 101 (e.g., to 50G)
qm disk resize 101 scsi0 50G

# 3. Configure Static IP, Gateway, and Hostname
qm set 101 --ipconfig0 ip=192.168.1.50/24,gw=192.168.1.1 --nameserver 1.1.1.1

# 4. Inject SSH Public Key & User
qm set 101 --ciuser ubuntu --sshkeys ~/.ssh/id_rsa.pub

# 5. Start the VM
qm start 101
```

#### Option B: Proxmox Web GUI

1. Right-click template `ubuntu-2404-cloudinit-template (9000)` -> **Clone**.
2. Specify:
   - **Mode**: Full Clone
   - **Target Storage**: Select `proxlake` from the dropdown.
   - **VM ID**: `101`
   - **Name**: `k8s-node-01`
3. Click **Clone**.
4. (Optional) Go to **Hardware** tab -> click **Hard Disk (scsi0)** -> **Disk Action** -> **Resize** to enlarge disk.
5. Select VM `101` -> Go to **Cloud-Init** tab in the left panel.
6. Set:
   - **User**: `ubuntu` (or preferred username)
   - **Password / SSH Public Key**: Paste your public key.
   - **IP Config (net0)**: Choose `Static` and enter `192.168.1.50/24` & Gateway `192.168.1.1`.
   - **DNS Domain / Servers**: Optional custom DNS.
7. Click **Regenerate Image** (if prompted) and **Start** the VM.

---

## 🔍 How Identity Machine Reset Works Under Cloud-Init

When the cloned VM boots up for the first time:
1. Cloud-Init reads Proxmox settings from the virtual drive attached to `--ide2`.
2. `/etc/machine-id` is initialized automatically by `systemd`.
3. OpenSSH host keys (`/etc/ssh/ssh_host_*`) are regenerated via `cloud-init`'s built-in `cc_ssh` module.
4. Netplan configuration is written automatically to `/etc/netplan/50-cloud-init.yaml`.
5. Root filesystem `/` is automatically grown to fill the `scsi0` disk size.

No login or manual script execution is required!
