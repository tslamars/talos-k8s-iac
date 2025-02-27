# Talos Kubernetes IaC Setup

This guide walks you through preparing your Linux workstation for managing Talos Kubernetes infrastructure as code (IaC). Below are the steps to install the required tools: Packer, Terraform, and Talosctl.

### Prepare the Workstation

#### Install Packer
Packer is used to build machine images. Install it with the following commands:

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install packer
packer -v
```

### Install Terraform

```bash
sudo apt update && sudo apt install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install terraform
terraform -v
```

### Install Talosctl

```bash
curl -sL https://talos.dev/install | sh
talosctl version --help
```

### Install Talhelper

```bash
curl https://i.jpillora.com/budimanjojo/talhelper! | sudo bash
talhelper -v
```

### Install Kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

### Install Sops

```bash
curl -LO https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64
mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops
chmod +x /usr/local/bin/sops
sops -v
```

### Install Age

```bash
sudo apt install age
age -version
```

### Install Cilium CLI

```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

### Proxmox related tasks

#### Add Proxmox token

- Generate an API token for Proxmox root user. Login to Proxmox web console using root user. Navigate to Datacenter → Permissions → API Tokens → Add. Select root (or another user with proper permissions) as the user, give a name for the token ID and click Add. Copy the token once displayed.

#### Download Arch Linux ISO

- Open a shell to the Proxmox node. From console select the Proxmox node → Shell.
- Download Arch Linux ISO, this is only used to copy Talos raw image.

```bash
cd /var/lib/vz/template/iso
wget https://geo.mirror.pkgbuild.com/iso/2024.06.01/archlinux-2025.02.01-x86_64.iso
```

#### Update local.pkrvars.hcl

- Update the packer/talos-packer/vars/local.pkrvars.hcl file in the cloned repository with the Proxmox node and Talos details.
- Run Packer to build the Talos template

```bash
cd $HOME/talos-k8s-iac/packer/talos-packer/
packer init -upgrade .
packer validate -var-file="vars/local.pkrvars.hcl" .
packer build -var-file="vars/local.pkrvars.hcl" .
```

#### Create Talos VMs using Terraform

Create a copy of talos-k8s-iac/terraform/tslamars-talos-cluster/example.credentials.auto.tfvars file as credentials.auto.tfvars and update the Proxmox node details. Delete the example file otherwise Terraform will bark.

```bash
cd $HOME/c0depool-iac/terraform/c0depool-talos-cluster/
cp example.credentials.auto.tfvars credentials.auto.tfvars
rm example.credentials.auto.tfvars
# Update the file credentials.auto.tfvars
```

Open tslamars-k8s-iac/terraform/tslamars-talos-cluster/locals.tf and add/remove the nodes according to your cluster requirements. By default I have 6 nodes: 3 masters and 3 workers. You should at least have one master and one worker. Here is an example configuration:

```
  vm_master_nodes = {
    "0" = {
      vm_id          = 200
      node_name      = "talos-master-00"
      clone_target   = "talos-v1.9.4-cloud-init-template"
      node_cpu_cores = "2"
      node_memory    = 2048
      node_ipconfig  = "ip=10.10.6.170/21,gw=10.10.0.1"
      node_disk      = "32" # in GB
    }
}
```

#### Run Terraform to provision the servers

```bash
cd $HOME/tslamars-k8s-iac/terraform/tslamars-talos-cluster/
# Initialize Terraform
terraform init
# Plan
terraform plan -out .tfplan
# Apply
terraform apply .tfplan
```