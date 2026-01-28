# Changelog

All notable changes to the Sovereign FinOps Platform project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

##  [1.0.0] - 2026-01-28

### Added
- 🎉 **Initial release** of Sovereign FinOps Platform
- **GitOps**: ArgoCD-based continuous delivery with 7 managed applications
- **Secrets Management**: HashiCorp Vault + External Secrets Operator integration
- **Policy Enforcement**: Kyverno with root-user disallow policy
- **Cost Monitoring**: OpenCost + Prometheus stack
- **Security CI/CD**: GitHub Actions with TFLint and Trivy scanning
- **Documentation**:
  - Comprehensive architecture guide with 7 Mermaid diagrams
  - Application dependency matrix with failure scenarios
  - Troubleshooting guide with FAQ from real deployment sessions
  - Annotated YAML manifests with inline comments
- **Platform Scripts**:
  - `start.ps1`: One-command launcher for all services
  - `scripts/verify.ps1`: Platform health check
  - `scripts/configure-vault.ps1`: Vault Kubernetes auth setup
  - `scripts/connect-dashboard.ps1`: Dashboard port-forwards

### Design Decisions

#### Why auto-sync is disabled for Kyverno
**Decision**: Disabled automated sync for Kyverno ArgoCD application

**Reason**: Kyverno's Helm chart contains a post-upgrade hook that:
1. Runs after main resources are deployed
2. Can fail due to image pull errors or other issues
3. Blocks ArgoCD sync indefinitely waiting for hook completion
4. Causes infinite sync loop with auto-sync enabled

**Trade-off**: Loss of GitOps self-healing for Kyverno, but stability gained

**Solution**: Manual sync required for Kyverno updates via ArgoCD UI

**Files Modified**:
- `argocd/applications/kyverno.yaml` - Removed `automated: {prune: true, selfHeal: true}`

---

#### Why ServerSideApply is enabled for Kyverno
**Decision**: Added `ServerSideApply=true` to Kyverno sync options

**Reason**: Kyverno CRDs are extremely large (ValidatingWebhookConfiguration, etc.) and exceed Kubernetes annotation size limit of 256KB. ArgoCD's default client-side apply stores the full resource manifest in annotations, causing:
```
error: metadata.annotations: Too long: must have at most 262144 bytes
```

**Solution**: Server-side apply performs diff/merge on the API server, avoiding annotation storage

**Files Modified**:
- `argocd/applications/kyverno.yaml` - Added `syncOptions: [ServerSideApply=true]`

---

#### Why SkipHooks is enabled for Kyverno
**Decision**: Added `SkipHooks=true` to K yverno sync options

**Reason**: Combined with auto-sync disabled, this prevents ArgoCD from executing Helm hooks that can fail and block sync

**Trade-off**: Hook functionality (cleanup, validation) is lost

**Files Modified**:
- `argocd/applications/kyverno.yaml` - Added `syncOptions: [SkipHooks=true]`

---

#### Why argocd and kube-system are excluded from root policy
**Decision**: Excluded `argocd` and `kube-system` namespaces from `disallow-root-user` policy

**Reason**: Critical system components require root access:
- **ArgoCD Server**: Runs as root by design (upstream behavior)
- **CoreDNS**: Binds to privileged port 53
- **kube-proxy**: Requires root for iptables manipulation
- **MetalLB**: Requires root for network operations

**Impact**: Without exclusions, these components fail to deploy and the platform breaks

**Files Modified**:
- `apps/policy/disallow-root.yaml` - Added `exclude.namespaces: [argocd, kube-system]`

---

#### Why Vault Kubernetes auth requires CA cert and token reviewer
**Decision**: Vault Kubernetes auth configured with:
- Kubernetes API CA certificate
- Service account token reviewer JWT
- Kubernetes API host

**Reason**: Vault needs to validate service account tokens presented by ESO. Without proper config:
- ESO authentication fails with `403 Permission Denied`
- ClusterSecretStore shows `Invalid` status
- Secrets cannot sync to Kubernetes

**How It Works**:
1. ESO sends its service account JWT to Vault
2. Vault sends a TokenReview request to Kubernetes API (requires CA cert)
3. Kubernetes validates the token and returns result
4. If valid, Vault issues a Vault token with ESO policy

**Files Modified**:
- `scripts/configure-vault.sh` - Reads CA cert and token from pod filesystem
- `scripts/configure-vault.ps1` - PowerShell wrapper for Windows

---

#### Why anonymous admin access is enabled for ArgoCD
**Decision**: Enabled anonymous admin access in ArgoCD for local demo

**Configuration**:
```yaml
server:
  rbacConfig:
    policy.default: role:admin
```

**Reason**: Simplifies local demo - no password required

**⚠️ SECURITY WARNING**: This is **HIGHLY INSECURE** and should **NEVER** be used in production

**Production Alternative**: Use SSO (OIDC/SAML), RBAC with least-privilege, and TLS

**Files Modified**:
- `argocd-values.yaml` - Enabled anonymous admin

---

### Technical Debt

#### Kyverno "Unknown" Sync Status
**Issue**: ArgoCD shows `Sync: Unknown` for Kyverno despite being healthy

**Root Cause**: Without auto-sync, ArgoCD cannot determine sync status for apps with non-standard CRD status fields (`.status.terminatingReplicas`)

**Impact**: Cosmetic only - Kyverno is fully functional

**Resolution**: Accepted as-is. Alternative would be re-enabling auto-sync with risks

---

#### No Network Policies
**Issue**: No NetworkPolicy resources deployed

**Impact**: No network segmentation between namespaces

**Future Work**: Implement deny-all default policies with explicit allow rules

---

#### No RBAC customization
**Issue**: Using default Kubernetes RBAC

**Impact**: Service accounts have broader permissions than necessary

**Future Work**: Implement least-privilege service accounts

---

### Breaking Changes

None (initial release)

---

### Security

#### Vulnerabilities Fixed
- None (initial release)

#### Security Enhancements
- Shift-left security: TFLint + Trivy in CI/CD
- Policy enforcement: Kyverno blocks root containers (except system namespaces)
- Secret management: Vault instead of plain Kubernetes Secrets

---

## [Unreleased]

### Planned Features
- Grafana dashboards for unified observability
- Alertmanager for proactive monitoring
- NetworkPolicies for network segmentation
- RBAC with least-privilege service accounts
- Multi-cluster support with ArgoCD ApplicationSets
- Chaos engineering tests with Chaos Mesh

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2026-01-28 | Initial release - Full platform deployment |

---

## Migration Guides

### Upgrading from Pre-1.0

Not applicable (initial release)

---

## Links

- [Architecture Documentation](docs/ARCHITECTURE.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- [GitHub Repository](https://github.com/jubinalexis/Sovereign_Finops_Platform)

---

**Maintained by**: Sovereign FinOps Platform Team  
**License**: MIT
