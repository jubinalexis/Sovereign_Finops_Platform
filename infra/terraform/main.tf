resource "kind_cluster" "default" {
  name = "sovereign-finops"
  # Utilisation d'une version stable de l'image de nœud Kubernetes
  node_image = "kindest/node:v1.29.2" 
  
  kind_config {
    kind       = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    
    # === Nœud Maître (Control Plane) ===
    node {
      role = "control-plane"
      # Mapping des ports pour exposer l'Ingress Controller (plus tard)
      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }
    
    # === Nœuds de Travail (Workers) ===
    # Simulation de redondance avec deux workers
    node {
      role = "worker"
    }
    
    node {
      role = "worker"
    }
  }
  
  # Attendre que le cluster soit totalement opérationnel avant de finir
  wait_for_ready = true
}
