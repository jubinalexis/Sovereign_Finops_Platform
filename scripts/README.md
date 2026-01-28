# Scripts Directory

This directory contains utility scripts for managing the Sovereign FinOps Platform.

## Configuration Scripts

### `configure-vault.sh`
Shell script that configures Vault with Kubernetes authentication, policies, and secrets. This script runs **inside** the Vault pod.

**Features:**
- Enables Kubernetes authentication method
- Configures Kubernetes auth with CA certificate and service account token
- Creates External Secrets Operator policy
- Sets up authentication role for ESO
- Creates test secrets

### `configure-vault.ps1`
PowerShell wrapper script for Windows that executes `configure-vault.sh` inside the Vault pod.

**Usage:**
```powershell
.\scripts\configure-vault.ps1
```

## Verification Scripts

### `verify.ps1`
Verifies the platform deployment status, including:
- Kubernetes nodes
- ArgoCD applications
- Critical pods (ArgoCD, Vault, ESO, Kyverno)
- ClusterSecretStore connectivity

**Usage:**
```powershell
.\scripts\verify.ps1
```

## Connection Scripts

### `connect-dashboard.ps1`
Establishes port-forwards for all platform dashboards and opens them in the browser.

**Services:**
- ArgoCD: http://localhost:8080
- Vault: http://localhost:8200
- OpenCost: http://localhost:9090

**Usage:**
```powershell
.\scripts\connect-dashboard.ps1
```

### `restaure-connexion.ps1`
Alternative connection script with enhanced error handling and hidden windows for port-forwards.

**Usage:**
```powershell
.\scripts\restaure-connexion.ps1
```

## Notes

- All PowerShell scripts are designed for Windows environments
- Shell scripts (`.sh`) are executed inside Kubernetes pods via `kubectl exec`
- Port-forward processes run in the background - close the PowerShell window to terminate them
