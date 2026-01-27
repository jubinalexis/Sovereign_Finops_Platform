resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "6.0.5" # Version stable compatible

  timeout = 600
  wait    = true

  # Optimisation Resource-Light (Local/Kind)
  set {
    name  = "redis-ha.enabled"
    value = "false"
  }

  set {
    name  = "controller.replicas"
    value = "1"
  }

  set {
    name  = "server.replicas"
    value = "1"
  }

  set {
    name  = "repoServer.replicas"
    value = "1"
  }

  set {
    name  = "applicationSet.replicaCount"
    value = "1"
  }

  # Désactivation TLS strict pour local
  set {
    name  = "server.extraArgs"
    value = "{--insecure}"
  }
}

output "argocd_admin_password_command" {
  description = "Commande pour récupérer le mot de passe admin initial"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
}

output "argocd_login_command" {
  description = "Commande pour accéder à l'UI ArgoCD"
  value       = "kubectl port-forward svc/argocd-server -n argocd 8080:443"
}
