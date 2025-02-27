# Talos Kubernetes IaC Setup

This guide walks you through preparing your Linux workstation for managing Talos Kubernetes infrastructure as code (IaC). Below are the steps to install the required tools: Packer, Terraform, and Talosctl.

### Credit

<div style="background-color: #ffcc00; padding: 15px; border: 1px solid #cc0000; border-radius: 5px; margin: 15px 0;">
  <strong>📌 Credit to c0depool</strong>  
  I want to give full credit and express my gratitude to the original author, c0depool, whose repository at <a href="https://github.com/c0depool/c0depool-iac">https://github.com/c0depool/c0depool-iac</a> served as the foundation for this project. I have modified and will continue to adapt it as I refine my Talos/Kubernetes setup. Thank you.
</div>

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

## Create Talos VMs using Terraform

Create a copy of talos-k8s-iac/terraform/tslamars-talos-cluster/example.credentials.auto.tfvars file as credentials.auto.tfvars and update the Proxmox node details. Delete the example file otherwise Terraform will bark.

```bash
cd $HOME/c0depool-iac/terraform/c0depool-talos-cluster/
cp example.credentials.auto.tfvars credentials.auto.tfvars
rm example.credentials.auto.tfvars
# Update the file credentials.auto.tfvars
```

Open talos-k8s-iac/terraform/tslamars-talos-cluster/locals.tf and add/remove the nodes according to your cluster requirements. By default I have 6 nodes: 3 masters and 3 workers. You should at least have one master and one worker. Here is an example configuration:

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
cd $HOME/talos-k8s-iac/terraform/tslamars-talos-cluster/
# Initialize Terraform
terraform init
# Plan
terraform plan -out .tfplan
# Apply
terraform apply .tfplan
```

## Generating Talos Configuration using Talhelper

- Update talos-k8s-iac/talos/talconfig.yaml according to your needs, add MAC addresses of the Talos nodes under hardwareAddr.
- Generate Talos secrets

```bash
cd $HOME/talos-k8s-iac/talos
talhelper gensecret > talsecret.sops.yaml
```

- Create Age secret key
```bash
mkdir -p $HOME/.config/sops/age/
age-keygen -o $HOME/.config/sops/age/keys.txt
```

- In the c0depool-iac/talos directory, create a .sops.yaml with below content

```bash
---
creation_rules:
  - age: <age-public-key> ## get this in the keys.txt file from previous step
```

- Encrypt Talos secrets with Age and Sops

```bash
cd $HOME/talos-k8s-iac/talos
sops -e -i talsecret.sops.yaml
```

- Generate Talos configuration

```bash
cd $HOME/talos-k8s-iac/talos
talhelper genconfig
```

## Bootsrap Talos

- Apply the corresponding configuration for each of your node from talos-k8s-iac/talos/clusterconfig directory

```bash
# For master node(s)
cd $HOME/talos-k8s-iac/talos/
talosctl apply-config --insecure --nodes <master-node ip> --file clusterconfig/<master-config>.yaml
# For worker(s)
talosctl apply-config --insecure --nodes <worker-node ip> --file clusterconfig/<worker-config>.yaml
```

- Wait for a few minutes for the nodes to reboot. Proceed with bootstrapping Talos

```bash
cd $HOME/talos-k8s-iac/talos/
# Copy Talos config to $HOME/.talos/config to avoid using --talosconfig
mkdir -p $HOME/.talos
cp clusterconfig/talosconfig $HOME/.talos/config
# Run the bootstrap command
# Note: The bootstrap operation should only be called ONCE on a SINGLE control plane/master node (use any one if you have multiple master nodes). 
talosctl bootstrap -n <master-node ip>
```

- Generate kubeconfig and save it to your home directory

```bash
mkdir -p $HOME/.kube
talosctl -n <master-node ip> kubeconfig $HOME/.kube/config
```

- Check the status of your nodes. Since we use Cilium for container networking, the nodes might not be in “Ready” state to accept workloads. We can fix it later by installing Cilium.

```bash
kubectl get nodes
```

## Install Cilium and L2 Load Balancer

Cilium is an open source, production ready, cloud native networking solution for Kubernetes. Talos by default uses a lightweight networking plugin called Flannel, which works perfectly fine for many. I just wanted to experiment with a production ready and secure networking solution. Additionally, since this is a bare-metal installation, we can make use of Cilium’s L2 aware load balancer to expose the LoadBalancer, as an alternative to MetalLB.

- Install Cilium using the cli

```bash
cilium install \
  --helm-set=ipam.mode=kubernetes \
  --helm-set=kubeProxyReplacement=true \
  --helm-set=securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
  --helm-set=securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
  --helm-set=cgroup.autoMount.enabled=false \
  --helm-set=cgroup.hostRoot=/sys/fs/cgroup \
  --helm-set=l2announcements.enabled=true \
  --helm-set=externalIPs.enabled=true \
  --helm-set=devices=eth+
  ```

- Verify your cluster. Now the nodes should be in “Ready” state
```bash
kubectl get nodes
kubectl get pods -A
```

Create CiliumLoadBalancerIPPool. For the pool cidr, it is mandatory to select a /30 or wider range so that we get at least 2 IPs after reserving the first and last ones. For eg if we use 10.10.6.100/30, we get 2 usable IPs 10.10.6.101 and 10.10.6.102. I am planning to use only one LoadBalancer service for the ingress controller, so this works for me.

```bash
cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "cilium-ip-pool"
spec:
  blocks:
  - start: "10.10.6.100"
    stop: "10.10.6.102"
EOF
```

- Create CiliumL2AnnouncementPolicy
```bash
cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2alpha1"
kind: CiliumL2AnnouncementPolicy
metadata:
  name: "cilium-l2-policy"
spec:
  interfaces:
  - eth0
  externalIPs: true
  loadBalancerIPs: true
EOF
```

- Install Ingress Nginx Controller with an annotation to use the Cilium L2 load balancer IP

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.externalTrafficPolicy="Local" \
  --set controller.kind="DaemonSet" \
  --set controller.service.annotations."io.cilium/lb-ipam-ips"="10.10.6.101"
# Check if the LB service has the EXTERNAL-IP assigned
kubectl get svc ingress-nginx-controller -n ingress-nginx
```

Your ingress-nginx now has an external IP 10.10.6.101 and all your ingress resources will be available via this IP.

## Install Longhorn

<div style="background-color: #ffcc00; padding: 10px; border: 1px solid #cc0000; border-radius: 5px;">
  <strong>⚠️ NOTE:</strong> I think Longhorn is working with the below instructions. Further testing is needed.
</div>

Since we have multiple kubernetes nodes, it is essential to have a distributed storage solution. While there are many solutions available like Rook-Ceph, Mayastor etc., I was already using Longhorn with my K3s cluster where I have all my applications backed up. Luckily Longhorn now supports Talos. In the Talos configuration, I have added an extraMount for the longhorn volume. Let us install Longhorn and use the volume as our disk.

- Create and Label the Namespace: Allow privileged Pods in longhorn-system

```bash
kubectl create namespace longhorn-system
kubectl label namespace longhorn-system pod-security.kubernetes.io/enforce=privileged --overwrite
kubectl label namespace longhorn-system pod-security.kubernetes.io/enforce-version=latest --overwrite
```

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --version 1.8.0 \
  --set defaultSettings.defaultDataPath="/var/mnt/longhorn" \
  --set tolerations[0].key="node-role.kubernetes.io/control-plane" \
  --set tolerations[0].operator="Exists" \
  --set tolerations[0].effect="NoSchedule" \
  --set nodeSelector."node-role.kubernetes.io/worker"="" \
  --set podSecurityPolicy.enabled=false \
  --set global.securityContext.runAsNonRoot=false \
  --set global.securityContext.allowPrivilegeEscalation=true \
  --set global.securityContext.capabilities.drop=[] \
  --set global.securityContext.privileged=true \
  --set global.securityContext.seccompProfile.type=""
```