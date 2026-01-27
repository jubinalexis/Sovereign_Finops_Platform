resource "kubernetes_namespace" "metallb" {
  metadata {
    name = "metallb-system"
  }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  namespace  = kubernetes_namespace.metallb.metadata[0].name
  version    = "0.14.3"

  # Wait for the controller to be ready
  wait    = true
  timeout = 300
}

# Configuration du pool d'adresses IP (IPAddressPool)
resource "kubernetes_manifest" "metallb_ip_pool" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = "default-pool"
      namespace = kubernetes_namespace.metallb.metadata[0].name
    }
    spec = {
      addresses = [var.metallb_ip_range]
    }
  }

  depends_on = [helm_release.metallb]
}

# Configuration de l'annonce L2 (L2Advertisement)
resource "kubernetes_manifest" "metallb_l2_advertisement" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "default-l2"
      namespace = kubernetes_namespace.metallb.metadata[0].name
    }
    spec = {
      ipAddressPools = ["default-pool"]
    }
  }

  depends_on = [helm_release.metallb, kubernetes_manifest.metallb_ip_pool]
}
