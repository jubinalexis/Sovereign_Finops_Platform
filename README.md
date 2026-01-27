# Sovereign FinOps Platform (Édition Cloud Privé)

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
![Terraform](https://img.shields.io/badge/terraform-validated-purple)
![Kubernetes](https://img.shields.io/badge/kubernetes-v1.29-blue)

## 📌 Résumé Exécutif
Ce projet déploie une **infrastructure Kubernetes de qualité production** en simulant un environnement "Air-Gapped" (souverain), typique des secteurs de la **Défense** ou **Bancaire**.

Il répond à deux impératifs stratégiques :
1.  **Souveraineté Numérique** : Autonomie totale sans dépendance aux Clouds publics (AWS/GKE).
2.  **Excellence FinOps** : Observabilité granulaire des coûts pour chaque microservice.

---

## 🏗️ Architecture Technique

Le flux complet, de l'utilisateur jusqu'à la base de données sécurisée :

```mermaid
graph LR
    User[Utilisateur] -- HTTPS --> LB[MetalLB LoadBalancer]
    LB -- Traffic --> Ingress[NGINX Ingress]
    
    subgraph "Cluster Kubernetes (Kind)"
        Ingress -- Routing --> Argo[ArgoCD UI]
        Ingress -- Routing --> OC[OpenCost Dashboard]
        Ingress -- Routing --> Apps[Applications Métier]
        
        Apps -- Fetch Secrets --> ESO[External Secrets Operator]
        ESO -- Sync --> Vault[HashiCorp Vault]
        OC -- Metrics --> Prom[Prometheus]
    end
    
    style Vault fill:#ff9900,stroke:#333,stroke-width:2px
    style ESO fill:#ff9900,stroke:#333,stroke-width:2px
    style OC fill:#46b898,stroke:#333,stroke-width:2px
```

### Stack Technologique
*   **Infrastructure** : Docker, Kind, Terraform.
*   **Réseau** : MetalLB (Layer 2), NGINX Ingress.
*   **GitOps** : ArgoCD (Pattern App-of-Apps).
*   **FinOps** : OpenCost, Prometheus.
*   **Sécurité** : HashiCorp Vault, External Secrets Operator.

---

## 📸 La Preuve par l'Image

### 1. FinOps : Monitoring des Coûts en Temps Réel
> Visualisation précise du coût par namespace, permettant une refacturation interne (Chargeback).

![Tableau de bord OpenCost](docs/images/opencost-dashboard.png)

### 2. GitOps : Synchronisation Automatisée
> ArgoCD assure que l'état du cluster correspond toujours au code Git (Single Source of Truth).

![ArgoCD Sync](docs/images/argocd-sync.png)

---

## 🚀 Démarrage Rapide

### Prérequis
*   Docker Desktop
*   Terraform
*   Git

### Installation (Windows / PowerShell)
Lancez simplement ces commandes pour ériger l'infrastructure complète :

```powershell
# 1. Cloner le projet
git clone https://github.com/jubinalexis/Sovereign_Finops_Platform.git
cd sovereign-finops-platform

# 2. Lancer l'infrastructure (via Terraform)
cd infra/terraform
terraform init
terraform apply -auto-approve

# 3. Vérifier que tout est vert !
cd ../..
.\scripts\verify.ps1
```

### Accès aux services
*   **ArgoCD** : `https://localhost:8080` (admin / via script vérif)
*   **OpenCost** : `http://localhost:9090`
*   **Vault** : `http://localhost:8200`