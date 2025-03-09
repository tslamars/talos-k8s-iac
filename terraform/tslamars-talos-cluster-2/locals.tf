locals {
  # Master Node configuration
  vm_master_nodes = {
    "0" = {
      vm_id          = 400
      node_name      = "talos-marsmaster-00"
      clone_target   = "talos-v1.9.4-cloud-init-template"
      node_cpu_cores = "2"
      node_memory    = 4096
      node_ipconfig  = "ip=10.10.5.170/21,gw=10.10.0.1"
      node_disk      = "32" # in GB
    }
    "1" = {
      vm_id          = 401
      node_name      = "talos-marsmaster-01"
      clone_target   = "talos-v1.9.4-cloud-init-template"
      node_cpu_cores = "2"
      node_memory    = 4096
      node_ipconfig  = "ip=10.10.5.171/21,gw=10.10.0.1"
      node_disk      = "32" # in GB
    }
    "2" = {
      vm_id          = 402
      node_name      = "talos-marsmaster-02"
      clone_target   = "talos-v1.9.4-cloud-init-template"
      node_cpu_cores = "2"
      node_memory    = 4096
      node_ipconfig  = "ip=10.10.5.172/21,gw=10.10.0.1"
      node_disk      = "32" # in GB
    }
  }
  # Worker Node configuration
  vm_worker_nodes = {
    "0" = {
      vm_id                = 500
      node_name            = "talos-marsworker-00"
      clone_target         = "talos-v1.9.4-cloud-init-template"
      node_cpu_cores       = "4"
      node_memory          = 8192
      node_ipconfig        = "ip=10.10.5.180/21,gw=10.10.0.1"
      node_disk            = "32"
      additional_node_disk = "128" # for longhorn
    }
    "1" = {
      vm_id                = 501
      node_name            = "talos-marsworker-01"
      clone_target         = "talos-v1.9.4-cloud-init-template"
      node_cpu_cores       = "4"
      node_memory          = 8192
      node_ipconfig        = "ip=10.10.5.181/21,gw=10.10.0.1"
      node_disk            = "32"
      additional_node_disk = "128" # for longhorn
    }
    "2" = {
      vm_id                = 502
      node_name            = "talos-marsworker-02"
      clone_target         = "talos-v1.9.4-cloud-init-template"
      node_cpu_cores       = "4"
      node_memory          = 8192
      node_ipconfig        = "ip=10.10.5.182/21,gw=10.10.0.1"
      node_disk            = "32"
      additional_node_disk = "128" # for longhorn
    }
  }
}
