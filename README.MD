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
VM_ID=9000 VM_NAME="ubuntu-2404-template" STORAGE="local-lvm" ./create-ubuntu24-template.sh
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

# 5. Convert VM to Template
qm template 9000
```

---

## ⚡ Deploying a New VM in Seconds

Once your template is created, deploy and customize new Ubuntu 24.04 VMs using either **Proxmox CLI** or the **Proxmox Web GUI**.

### 💾 Specifying Target Storage for VM Disks (e.g. `proxlake`)

You can easily place the cloned VM's `scsi0` disk onto a specific storage target (such as `proxlake` or any other storage pool), even if the template itself was created on `local-lvm`.

#### Option A: Proxmox CLI (`qm` commands)

Pass `--storage proxlake` (with `--full`) when cloning the template:

```bash
# 1. Clone template (ID 9000) to new VM (ID 101) with disk on 'proxlake'
qm clone 9000 101 --name k8s-node-01 --storage proxlake --full

# 2. Configure Static IP, Gateway, and Hostname
qm set 101 --ipconfig0 ip=192.168.1.50/24,gw=192.168.1.1 --nameserver 1.1.1.1

# 3. Inject SSH Public Key & User
qm set 101 --ciuser ubuntu --sshkeys ~/.ssh/id_rsa.pub

# 4. Start the VM
qm start 101
```

> **Note**: If a VM was already cloned onto another storage, you can move its `scsi0` disk to `proxlake` anytime using:
> ```bash
> qm disk move 101 scsi0 proxlake --delete
> ```

#### Option B: Proxmox Web GUI

1. Right-click template `ubuntu-2404-cloudinit-template (9000)` -> **Clone**.
2. Specify:
   - **Mode**: Full Clone
   - **Target Storage**: Select `proxlake` from the dropdown.
   - **VM ID**: `101`
   - **Name**: `k8s-node-01`
3. Click **Clone**.
4. Select the new VM `101` -> Go to **Cloud-Init** tab in the left panel.
5. Set:
   - **User**: `ubuntu` (or preferred username)
   - **Password / SSH Public Key**: Paste your public key.
   - **IP Config (net0)**: Choose `Static` and enter `192.168.1.50/24` & Gateway `192.168.1.1`.
   - **DNS Domain / Servers**: Optional custom DNS.
6. Click **Regenerate Image** (if prompted) and **Start** the VM.

---

## 🔍 How Identity Machine Reset Works Under Cloud-Init

When the cloned VM boots up for the first time:
1. Cloud-Init reads Proxmox settings from the virtual drive attached to `--ide2`.
2. `/etc/machine-id` is initialized automatically by `systemd`.
3. OpenSSH host keys (`/etc/ssh/ssh_host_*`) are regenerated via `cloud-init`'s built-in `cc_ssh` module.
4. Netplan configuration is written automatically to `/etc/netplan/50-cloud-init.yaml`.

No login or manual script execution is required!
