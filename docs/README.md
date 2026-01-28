# Documentation Index

Welcome to the Sovereign FinOps Platform documentation!

## 📖 Quick Navigation

### Getting Started
- [Main README](../README.md) - Project overview and quick start guide
- [Quick Start Script](../start.ps1) - One-command platform launcher

### Architecture Documentation
- [**Architecture Overview**](ARCHITECTURE.md) - **START HERE!** Complete system architecture with diagrams
  - Component architecture diagram
  - Data flow between services
  - Vault → ESO secret synchronization sequence
  - Network topology
  - GitOps workflow
  - Security architecture

- [**Application Dependencies**](DEPENDENCIES.md) - Component dependency matrix
  - Dependency graph and deployment order
  - Sync wave recommendations
  - Failure impact analysis
  - Recovery procedures

### Operational Guides
- [Scripts Documentation](../scripts/README.md) - Automation scripts usage
- [Access Information](../ACCESS_INFOS.md) - Service URLs and credentials

## 📊 Diagrams Overview

The documentation includes the following **Mermaid diagrams**:

### Architecture Diagrams
1. **High-Level Architecture** - Shows all platform components and their relationships
2. **Component Interaction Flow** - Sequence diagram of deployment workflow
3. **Secret Management Flow** - Detailed Vault → ESO → K8s secret synchronization
4. **Application Dependencies Graph** - Visual dependency tree
5. **Network Architecture** - Network topology and port-forwarding setup
6. **GitOps Workflow** - Developer → Git → CI → ArgoCD → Kubernetes flow
7. **Security Architecture** - Defense-in-depth layers

### Dependency Diagrams
1. **Deployment Dependency Graph** - Sync wave visualization
2. **Detailed Dependency Matrix** - Table format with all dependencies

## 🎯 Documentation by Role

### For Developers
1. Read [Quick Start](../README.md#quick-start)
2. Understand [GitOps Workflow](ARCHITECTURE.md#gitops-workflow)
3. Review [Scripts Documentation](../scripts/README.md)

### For Platform Engineers
1. Study [Architecture Overview](ARCHITECTURE.md)
2. Understand [Application Dependencies](DEPENDENCIES.md)
3. Review [Secret Management Flow](ARCHITECTURE.md#secret-management-flow)
4. Plan with [Sync Wave Recommendations](DEPENDENCIES.md#recommended-sync-wave-annotations)

### For Security Teams
1. Review [Security Architecture](ARCHITECTURE.md#security-architecture)
2. Examine [Vault Authentication Flow](ARCHITECTURE.md#vault--eso--kubernetes-secret-synchronization)
3. Check [Current Security Controls](ARCHITECTURE.md#current-security-controls)

### For Cost Management
1. Understand [OpenCost Integration](ARCHITECTURE.md#component-descriptions)
2. Review [Prometheus Dependencies](DEPENDENCIES.md#prometheus)
3. See [Cost Monitoring Stack](ARCHITECTURE.md#monitoring--cost)

## 🔍 Quick Reference

### Service Endpoints
- **ArgoCD**: http://localhost:8080 (anonymous access enabled)
- **Vault**: http://localhost:8200 (token: `root`)
- **OpenCost**: http://localhost:9090

### Common Commands
```powershell
# Start all services
.\start.ps1

# Verify platform status
.\scripts\verify.ps1

# Configure Vault
.\scripts\configure-vault.ps1
```

### Key Concepts

**GitOps**: All infrastructure and application configuration stored in Git. ArgoCD syncs Git → Cluster.

**Secret Management**: Vault stores secrets → ESO syncs to K8s → Apps consume K8s Secrets.

**Policy Enforcement**: Kyverno validates resources at admission time. Non-compliant resources are rejected.

**Cost Monitoring**: Prometheus collects metrics → OpenCost calculates costs per namespace/label.

## 📚 External Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [HashiCorp Vault Docs](https://developer.hashicorp.com/vault/docs)
- [External Secrets Operator](https://external-secrets.io/)
- [Kyverno Policies](https://kyverno.io/policies/)
- [OpenCost Documentation](https://www.opencost.io/docs/)

## 🤝 Contributing

See the main [README Contributing section](../README.md#contributing) for contribution guidelines.

## 📝 Document Maintenance

| Document | Last Updated | Maintainer | Status |
|----------|--------------|------------|--------|
| ARCHITECTURE.md | 2026-01-28 | Platform Team | ✅ Current |
| DEPENDENCIES.md | 2026-01-28 | Platform Team | ✅ Current |
| README (scripts) | 2026-01-28 | Platform Team | ✅ Current |

---

**Questions?** Open an issue on [GitHub](https://github.com/jubinalexis/Sovereign_Finops_Platform/issues).
