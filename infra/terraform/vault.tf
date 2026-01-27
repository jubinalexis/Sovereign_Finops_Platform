resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  namespace  = kubernetes_namespace.vault.metadata[0].name
  version    = "0.32.0" 

  timeout = 600
  wait    = true

  # Mode DEV pour la simplicité locale (stockage en mémoire, pas de unseal manuel)
  set {
    name  = "server.dev.enabled"
    value = "true"
  }

  # Exposition via Service pour accès externe (Port Forwarding ou Ingress)
  set {
    name  = "ui.enabled"
    value = "true"
  }
  
  set {
      name = "ui.serviceType"
      value = "ClusterIP"
  }
}
