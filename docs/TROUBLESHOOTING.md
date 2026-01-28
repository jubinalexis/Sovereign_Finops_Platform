# Troubleshooting Guide

This guide covers common issues encountered with the Sovereign FinOps Platform and their solutions.

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Common Issues](#common-issues)
- [Component-Specific Issues](#component-specific-issues)
- [FAQ](#faq)

---

## Quick Diagnostics

### Check Platform Status

```powershell
# Verify all components
.\scripts\verify.ps1

# Check ArgoCD applications
kubectl get application -n argocd

# Check pod health across all namespaces
kubectl get pods --all-namespaces | Where-Object { $_ -notmatch "Running|Completed" }

# Check ClusterSecretStore status
kubectl get clustersecretstore vault-backend -o jsonpath="{.status.conditions[0].message}"
```

### Common Diagnostic Commands

```powershell
# View ArgoCD application details
kubectl describe application <app-name> -n argocd

# Check recent events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# View pod logs
kubectl logs <pod-name> -n <namespace>

# Check Kyverno policy reports
kubectl get policyreport -A
```

---

## Common Issues

### 🔴 Issue: Kyverno Shows "Unknown" Sync Status

**Symptoms:**
- ArgoCD UI shows `Sync: Unknown` for Kyverno
- Application health is `Healthy`
- All Kyverno pods are running

**Root Cause:**
Auto-sync is disabled for Kyverno to prevent a sync loop caused by failing Helm post-upgrade hooks. ArgoCD cannot determine sync status without auto-sync enabled for apps with certain CRD status fields.

**Impact:** 
✅ None - purely cosmetic. Kyverno is fully functional.

**Solution:**
Accept the "Unknown" status or manually sync when needed:

```powershell
kubectl annotate application kyverno -n argocd argocd.argoproj.io/refresh=hard --overwrite
```

**Prevention:**
This is the intended configuration. Do not re-enable auto-sync for Kyverno.

---

### 🔴 Issue: ArgoCD Shows "Connection Refused" (localhost:8080)

**Symptoms:**
- Browser shows `ERR_CONNECTION_REFUSED` when accessing http://localhost:8080
- Port-forward appears to be running

**Root Cause:**
1. ArgoCD Server pod is not running
2. Port-forward process died
3. ArgoCD Server is blocked by Kyverno policy

**Diagnosis:**

```powershell
# Check if ArgoCD Server pod exists
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server

# Check port-forward processes
Get-Process -Name kubectl | Select-Object Id, StartTime

# Check for policy violations
kubectl describe application argocd-server -n argocd | Select-String "PolicyViolation"
```

**Solution:**

```powershell
# Restart port-forwards
Stop-Process -Name kubectl -Force
.\start.ps1

# If pod doesn't exist, check deployment
kubectl get deployment argocd-server -n argocd

# If policy violation, the root policy may be blocking ArgoCD
# Verify namespace exclusions in disallow-root.yaml
kubectl get clusterpolicy disallow-root-user -o yaml
```

---

### 🔴 Issue: ClusterSecretStore Shows "Invalid" Status

**Symptoms:**
- `kubectl get clustersecretstore vault-backend` shows `Ready: False`
- Status message: `403 Permission Denied` or `Connection refused`

**Root Cause:**
Vault Kubernetes authentication is not properly configured with:
- Kubernetes CA certificate
- Service account token reviewer
- Correct Kubernetes API host

**Diagnosis:**

```powershell
# Check ClusterSecretStore status
kubectl describe clustersecretstore vault-backend

# Check Vault auth config
kubectl exec -n vault vault-0 -- vault read auth/kubernetes/config

# Test ESO service account
kubectl get sa external-secrets -n external-secrets
```

**Solution:**

```powershell
# Reconfigure Vault Kubernetes auth
.\scripts\configure-vault.ps1

# Verify configuration
kubectl exec -n vault vault-0 -- vault read auth/kubernetes/config

# Wait 30 seconds for ESO to reconnect, then check
kubectl get clustersecretstore vault-backend -o jsonpath="{.status.conditions}"
```

---

### 🔴 Issue: Kyverno Post-Upgrade Hook Job Failing

**Symptoms:**
- Kyverno shows `Syncing` in ArgoCD indefinitely
- Job `kyverno-hook-post-upgrade` is in `CrashLoopBackOff` or `ImagePullBackOff`
- ArgoCD sync never completes

**Root Cause:**
The Helm post-upgrade hook tries to pull an image that may not be accessible or the job fails for another reason. ArgoCD waits for all hooks to complete before marking sync as successful.

**Solution:**

```powershell
# Delete the failing hook job
kubectl delete job kyverno-hook-post-upgrade -n kyverno --force --grace-period=0

# Verify Kyverno.yaml has SkipHooks enabled (it should)
cat argocd/applications/kyverno.yaml | Select-String "SkipHooks"

# If auto-sync is enabled, disable it to prevent recreation
# (Already disabled in this project)
```

**Prevention:**
- Auto-sync is disabled for Kyverno in this project
- `SkipHooks=true` is configured (but doesn't always work with auto-sync)

---

### 🔴 Issue: Policy Blocks ArgoCD or System Pods

**Symptoms:**
- ArgoCD Server pod won't start
- Event: `PolicyViolation: Running as root is not allowed`
- System pods in `kube-system` fail to deploy

**Root Cause:**
The `disallow-root-user` Kyverno policy is enforced on system namespaces that require root access.

**Diagnosis:**

```powershell
# Check policy violations
kubectl describe pod <pod-name> -n <namespace> | Select-String "PolicyViolation"

# Check which namespaces are excluded
kubectl get clusterpolicy disallow-root-user -o jsonpath="{.spec.rules[0].exclude}"
```

**Solution:**

Verify `apps/policy/disallow-root.yaml` excludes system namespaces:

```yaml
spec:
  rules:
    - name: check-runasnonroot
      exclude:
        any:
        - resources:
            namespaces:
            - argocd        # ← Must be excluded
            - kube-system   # ← Must be excluded
```

Apply the updated policy:

```powershell
kubectl apply -f apps/policy/disallow-root.yaml
kubectl rollout restart deployment argocd-server -n argocd
```

---

### 🔴 Issue: "Metadata too long" Error in ArgoCD

**Symptoms:**
- ArgoCD shows error: `metadata.annotations: Too long: must have at most 262144 bytes`
- Typically happens with Kyverno or other large CRDs

**Root Cause:**
ArgoCD uses client-side apply by default, which stores the entire resource manifest in annotations. Large CRDs exceed the 256KB annotation limit.

**Solution:**

Add `ServerSideApply=true` to the ArgoCD Application syncOptions:

```yaml
# argocd/applications/kyverno.yaml
spec:
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true  # ← Required for large CRDs
```

Apply the change:

```powershell
git add argocd/applications/kyverno.yaml
git commit -m "fix: enable ServerSideApply for Kyverno"
git push
```

ArgoCD will auto-sync and apply the fix.

---

## Component-Specific Issues

### Vault

#### Vault Pod Not Starting

```powershell
# Check pod status
kubectl get pods -n vault

# View logs
kubectl logs vault-0 -n vault

# Common issues:
# - PVC not bound (check storage class)
# - Resource limits too low
# - Init container failing
```

#### Vault Sealed After Restart

```powershell
# Check seal status
kubectl exec -n vault vault-0 -- vault status

# In dev mode, Vault should auto-unseal
# If sealed in production, unseal manually:
kubectl exec -n vault vault-0 -- vault operator unseal <unseal-key>
```

---

### External Secrets Operator

#### Secrets Not Syncing

```powershell
# Check ESO controller logs
kubectl logs -n external-secrets deployment/external-secrets -f

# Check ExternalSecret status
kubectl get externalsecret -n <namespace>
kubectl describe externalsecret <name> -n <namespace>

# Common issues:
# - ClusterSecretStore invalid (see above)
# - Secret path doesn't exist in Vault
# - Refresh interval not elapsed (default 1h)
```

#### Force Secret Refresh

```powershell
# Annotate ExternalSecret to force refresh
kubectl annotate externalsecret <name> -n <namespace> force-sync="$(Get-Date)" --overwrite
```

---

### Kyverno

#### Policy Not Enforcing

```powershell
# Check Kyverno admission controller
kubectl get validatingwebhookconfigurations | Select-String "kyverno"

# Check policy status
kubectl get clusterpolicy
kubectl describe clusterpolicy <policy-name>

# Verify policy is not in Audit mode
# Should be: validationFailureAction: Enforce
```

#### Background Scan Not Working

```powershell
# Check background controller logs
kubectl logs -n kyverno deployment/kyverno-background-controller -f

# Trigger manual scan
kubectl annotate clusterpolicy <policy-name> policies.kyverno.io/scored="true" --overwrite
```

---

### Prometheus & OpenCost

#### OpenCost Shows No Data

```powershell
# Verify Prometheus is scraping
kubectl port-forward -n prometheus svc/prometheus 9090:9090
# Open http://localhost:9090/targets

# Check OpenCost can reach Prometheus
kubectl logs -n opencost deployment/opencost -f | Select-String "prometheus"

# Verify configuration
kubectl get configmap opencost -n opencost -o yaml
```

---

## FAQ

### Q: Why is auto-sync disabled for Kyverno?

**A:** Auto-sync causes a continuous loop:
1. ArgoCD syncs Kyverno
2. Helm post-upgrade hook job is created
3. Hook job fails (image pull or other error)
4. ArgoCD marks as "OutOfSync" and tries again
5. Repeat indefinitely

Disabling auto-sync + adding `SkipHooks=true` breaks this loop. Manual sync is required for Kyverno updates.

---

### Q: Why does Kyverno show "Unknown" instead of "Synced"?

**A:** ArgoCD cannot determine sync status for applications without auto-sync when they have CRDs with non-standard status fields (like `.status.terminatingReplicas`). This is a known ArgoCD limitation and doesn't affect functionality.

---

### Q: Can I use the disallow-root policy in production?

**A:** Yes, but you must carefully exclude system namespaces that require root:
- `kube-system` (CoreDNS, kube-proxy, etc.)
- `argocd` (ArgoCD Server runs as root)
- Any other infrastructure namespaces

Test thoroughly in staging first.

---

### Q: How often does ESO sync secrets from Vault?

**A:** Default refresh interval is **1 hour**. You can configure this per ExternalSecret:

```yaml
spec:
  refreshInterval: 15m  # Faster sync (more Vault load)
```

For immediate sync, annotate the ExternalSecret (see "Force Secret Refresh" above).

---

### Q: What happens if Vault goes down?

**A:** 
- ✅ Existing Kubernetes Secrets remain available (cached)
- ✅ Running applications continue to work
- ❌ New secrets cannot be synced
- ❌ Applications depending on new secrets will fail to start

**Recovery:** Fix Vault, ESO reconnects automatically.

---

### Q: Why use Port-Forward instead of Ingress?

**A:** This is a **local demo** environment running on kind. Port-forwarding is simpler than:
- Setting up Ingress controller
- Configuring DNS (via `/etc/hosts` or local DNS)
- Managing TLS certificates

For production, use Ingress + LoadBalancer + proper DNS.

---

### Q: Can I enable anonymous access to ArgoCD in production?

**A:** **NO!** Anonymous admin access (`admin.enabled: true` + `server.rbacConfig`) is **HIGHLY INSECURE**. Only use for local demos.

Production setup:
- Disable anonymous access
- Use SSO (OIDC, SAML, LDAP)
- Enable RBAC with least-privilege
- Use TLS with valid certificates

---

### Q: How do I add a new Kyverno policy?

**Steps:**
```powershell
# 1. Create policy file
New-Item apps/policy/my-new-policy.yaml

# 2. Git commit
git add apps/policy/my-new-policy.yaml
git commit -m "feat: add my-new-policy"
git push

# 3. ArgoCD auto-syncs (security-policies app)
# Verify:
kubectl get clusterpolicy my-new-policy
```

---

### Q: How do I rollback a deployment?

**A:** GitOps principle: rollback in Git

```powershell
# Option 1: Git revert
git log  # Find commit hash to revert
git revert <commit-hash>
git push

# Option 2: Manual ArgoCD sync to previous commit
# In ArgoCD UI: Select application → Sync → Advanced → Revision → <previous-commit-hash>
```

---

### Q: What's the `ServerSideApply=true` sync option?

**A:** Server-side apply is a Kubernetes feature that:
- Performs diff/merge on the server (not client)
- Doesn't store full manifest in annotations
- Required for large CRDs (like Kyverno) that exceed annotation size limits

Without it, you get "metadata.annotations: Too long" errors.

---

### Q: How do I upgrade component versions (e.g., Vault chart)?

**Steps:**
```powershell
# 1. Update version in Terraform
# infra/terraform/vault.tf
resource "helm_release" "vault" {
  version    = "0.33.0"  # Update version
  ...
}

# 2. Apply Terraform
cd infra/terraform
terraform plan
terraform apply

# 3. Verify
kubectl get pods -n vault
```

---

## Performance Optimization

### Reduce ArgoCD Sync Interval

Default: 3 minutes

```yaml
# argocd-values.yaml
controller:
  args:
    - --sync-timeout
    - 300
    - --repo-poll-interval
    - 60  # 1 minute instead of 3
```

**Trade-off:** More frequent Git polls = more load on Git server

---

### Reduce ESO Refresh Interval

Default: 1 hour per ExternalSecret

```yaml
# externalSecret.yaml
spec:
  refreshInterval: 5m  # Sync every 5 minutes
```

**Trade-off:** More frequent syncs = more load on Vault

---

## Debug Mode

### Enable Debug Logs for ESO

```powershell
kubectl set env deployment/external-secrets -n external-secrets LOG_LEVEL=debug
kubectl logs -n external-secrets deployment/external-secrets -f
```

### Enable Debug Logs for Kyverno

```powershell
kubectl set env deployment/kyverno-admission-controller -n kyverno LOG_LEVEL=6
kubectl logs -n kyverno deployment/kyverno-admission-controller -f
```

---

## Getting Help

1. **Check this guide** first
2. **Review logs** with commands above
3. **Check GitHub Issues**: https://github.com/jubinalexis/Sovereign_Finops_Platform/issues
4. **Component docs**:
   - [ArgoCD Troubleshooting](https://argo-cd.readthedocs.io/en/stable/operator-manual/troubleshooting/)
   - [Vault Troubleshooting](https://developer.hashicorp.com/vault/docs/troubleshooting)
   - [ESO Troubleshooting](https://external-secrets.io/latest/guides/common-k8s-secret-errors/)
   - [Kyverno Troubleshooting](https://kyverno.io/docs/troubleshooting/)

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-28  
**Feedback:** Open an issue if this guide doesn't cover your problem!
