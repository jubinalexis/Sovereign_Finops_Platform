# ⚠️ IMPORTANT SECURITY NOTICE

## 🔒 Current Configuration: DEVELOPMENT MODE

This project is currently configured for **LOCAL DEVELOPMENT ONLY**. The following insecure settings are enabled:

### ❌ INSECURE Settings (Active)

1. **ArgoCD Anonymous Admin Access** (`argocd-values.yaml`)
   - Anyone can access ArgoCD without authentication
   - Full admin privileges granted to anonymous users
   - **NEVER use this in production!**

2. **HTTP Only (No TLS)** (`argocd-values.yaml`)
   - Traffic is not encrypted
   - Vulnerable to man-in-the-middle attacks
   - **NEVER use this in production!**

3. **Root Vault Token** (scripts/configure-vault.sh)
   - Using `root` token for all Vault operations
   - No token rotation or expiration
   - **NEVER use this in production!**

---

## ✅ Migrating to Production

### Before Deploying to Production:

#### 1. Use Production ArgoCD Configuration

```bash
# DO NOT USE: argocd-values.yaml (dev mode, insecure!)
# USE THIS: argocd-values-prod.yaml
```

**Required changes in `argocd-values-prod.yaml`**:
- ✅ Enable TLS with valid certificates
- ✅ Configure SSO (OIDC/SAML)
- ✅ Disable anonymous access
- ✅ Implement RBAC with least-privilege
- ✅ Enable high availability (replicas: 3)
- ✅ Configure network policies

#### 2. Run Security Validation

```powershell
# Validate production configuration
.\scripts\validate-security.ps1 -Environment prod
```

This script checks for:
- Anonymous access (BLOCKED in prod)
- TLS configuration (REQUIRED in prod)
- SSO setup (RECOMMENDED)
- Hardcoded credentials (REJECTED)
- RBAC policies (VALIDATED)

#### 3. Enable Secret Scanning

```powershell
# Install pre-commit hook
.\scripts\install-git-hooks.ps1
```

This enables:
- Gitleaks secret scanning before each commit
- Pattern-based credential detection
- Large file prevention (>10MB)

#### 4. Review RBAC Configuration

See **[docs/RBAC.md](docs/RBAC.md)** for:
- ArgoCD RBAC examples
- Kubernetes service account best practices
- Least-privilege role definitions

---

## 🛡️ Security Features Implemented

### ✅ Already Configured

1. **Secret Scanning CI/CD**
   - Gitleaks runs on every push/PR
   - Blocks commits with detected secrets
   - See `.github/workflows/ci.yml`

2. **Pre-Commit Hooks**
   - Local secret scanning before git commit
   - Prevents accidental secret commits
   - See `.githooks/pre-commit`

3. **Environment Separation**
   - `argocd-values-dev.yaml` - Development (current)
   - `argocd-values-prod.yaml` - Production (secure)

4. **Enhanced .gitignore**
   - Blocks 50+ secret file types
   - Prevents credential files from being committed
   - See `.gitignore`

5. **Security Validation Script**
   - Automated security checks
   - Validates config before deployment
   - See `scripts/validate-security.ps1`

6. **RBAC Documentation**
   - Complete RBAC guide with examples
   - Least-privilege service account templates
   - See `docs/RBAC.md`

---

## 📋 Production Deployment Checklist

Before deploying to production, ensure:

- [ ] Using `argocd-values-prod.yaml` (NOT `argocd-values.yaml`)
- [ ] TLS enabled with valid certificates
- [ ] SSO configured (OIDC/SAML/LDAP)
- [ ] Anonymous access disabled
- [ ] RBAC policies configured with least-privilege
- [ ] All secrets stored in Vault (not Git)
- [ ] Secret scanning enabled in CI/CD
- [ ] Pre-commit hooks installed
- [ ] Ran `validate-security.ps1` successfully
- [ ] Network policies configured
- [ ] High availability enabled (replicas ≥ 3)
- [ ] Resource limits configured
- [ ] Monitoring and alerting set up
- [ ] Backup/restore procedures documented
- [ ] Incident response runbooks created

---

## 🚨 If You Accidentally Committed a Secret

### Immediate Actions:

1. **Revoke the secret immediately**
   ```bash
   # Example: Rotate AWS keys, revoke API tokens, change passwords
   ```

2. **Remove from Git history**
   ```bash
   # Use BFG Repo-Cleaner or git-filter-repo
   git filter-repo --path <file-with-secret> --invert-paths
   ```

3. **Force push** (if repository is private and you control all clones)
   ```bash
   git push origin --force --all
   ```

4. **Notify security team**

5. **Update `.gitignore` and `.gitleaksignore`** to prevent recurrence

---

## 📚 Security Resources

- [Security Documentation](docs/RBAC.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- [Architecture Security](docs/ARCHITECTURE.md#security-architecture)
- [OWASP Kubernetes Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)

---

## ⚙️ Quick Commands

```powershell
# Validate security for production
.\scripts\validate-security.ps1 -Environment prod

# Install pre-commit hooks
.\scripts\install-git-hooks.ps1

# Scan for secrets manually
gitleaks detect --source . --verbose

# Check RBAC permissions
kubectl auth can-i --list --as=system:serviceaccount:default:myapp-sa
```

---

**Last Updated**: 2026-01-28  
**⚠️ REMEMBER**: The current configuration is for LOCAL DEVELOPMENT ONLY. Follow this guide before deploying to production!
