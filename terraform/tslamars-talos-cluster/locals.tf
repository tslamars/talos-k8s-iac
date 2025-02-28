locals {
  # Master Node configuration
  vm_master_nodes = {
    "0" = {
      vm_id          = 200
      node_name      = "talos-master-00"
      clone_target   = "talos-v1.9.4-cloud-init-template"
      node_cpu_cores = "2"
      node_memory    = 4096
      node_ipconfig  = "ip=10.10.4.170/21,gw=10.10.0.1"
      node_disk      = "32" # in GB
    }
    "1" = {
      vm_id          = 201
      node_name      = "talos-master-01"
      clone_target   = "talos-v1.9.4-cloud-init-template"
      node_cpu_cores = "2"
      node_memory    = 4096
      node_ipconfig  = "ip=10.10.4.171/21,gw=10.10.0.1"
      node_disk      = "32" # in GB
    }
    "2" = {
      vm_id          = 202
      node_name      = "talos-master-02"
      clone_target   = "talos-v1.9.4-cloud-init-template"
      node_cpu_cores = "2"
      node_memory    = 4096
      node_ipconfig  = "ip=10.10.4.172/21,gw=10.10.0.1"
      node_disk      = "32" # in GB
    }
  }
  # Worker Node configuration
  vm_worker_nodes = {
    "0" = {
      vm_id                = 300
      node_name            = "talos-worker-00"
      clone_target         = "talos-v1.9.4-cloud-init-template"
      node_cpu_cores       = "4"
      node_memory          = 8192
      node_ipconfig        = "ip=10.10.4.180/21,gw=10.10.0.1"
      node_disk            = "32"
      additional_node_disk = "128" # for longhorn
    }
    "1" = {
      vm_id                = 301
      node_name            = "talos-worker-01"
      clone_target         = "talos-v1.9.4-cloud-init-template"
      node_cpu_cores       = "4"
      node_memory          = 8192
      node_ipconfig        = "ip=10.10.4.181/21,gw=10.10.0.1"
      node_disk            = "32"
      additional_node_disk = "128" # for longhorn
    }
    "2" = {
      vm_id                = 302
      node_name            = "talos-worker-02"
      clone_target         = "talos-v1.9.4-cloud-init-template"
      node_cpu_cores       = "4"
      node_memory          = 8192
      node_ipconfig        = "ip=10.10.4.182/21,gw=10.10.0.1"
      node_disk            = "32"
      additional_node_disk = "128" # for longhorn
    }
  }
}
