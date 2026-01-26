# Sovereign FinOps Platform (Édition Cloud Privé)

## Résumé Exécutif
Ce projet a pour but de déployer une **infrastructure Kubernetes de qualité production** en simulant un environnement "Air-Gapped" (déconnecté/souverain) typique des secteurs de la Défense ou Bancaire Suisse.

Il met l'accent sur deux piliers critiques :
1.  **Souveraineté des Données** : Infrastructure autonome sans dépendance aux services managés cloud (EKS/GKE).
2.  **FinOps** : Observabilité précise des coûts, même sur du matériel "on-premise".

## Architecture Technique

### 1. Infrastructure (Le Hardware Virtuel)
*   **Hyperviseur** : Docker
*   **Orchestration** : Kind (Kubernetes in Docker) en mode Cluster (1 Control Plane, 2 Workers)
*   **Provisioning** : Terraform (Infrastructure as Code)

### 2. Réseau (La Plomberie)
*   **Load Balancing (L2)** : MetalLB pour l'attribution d'IPs locales.
*   **Ingress** : NGINX Ingress Controller.

### 3. Observabilité & FinOps
*   **Métriques** : Prometheus Node Exporter.
*   **Coûts** : OpenCost avec un modèle de tarification personnalisé (simulation de coûts CPU/RAM fictifs).

## Structure du Projet

```bash
/sovereign-finops-platform
├── infra/
│   └── terraform/       # Code Terraform pour le déploiement du cluster
├── Makefile             # Commandes d'automatisation
└── README.md            # Ce fichier
```

## Démarrage Rapide

### Prérequis
*   Docker Desktop
*   Terraform
*   Kind (Kubernetes in Docker)

### Installation
Pour lancer l'infrastructure complète :

```bash
make infra-up
```

Cela va :
1.  Initialiser Terraform.
2.  Créer le cluster Kubernetes local avec 3 nœuds.
3.  Vérifier que les nœuds sont prêts.

Pour détruire l'environnement :

```bash
make infra-down
```