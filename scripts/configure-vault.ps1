# Vault Configuration Script (Windows PowerShell Wrapper)
# Executes the configuration inside the Vault pod

Write-Host "=== Configuring Vault for Kubernetes Integration ===" -ForegroundColor Cyan

# Copy the configuration script to the Vault pod
Write-Host "Copying configuration script to Vault pod..." -ForegroundColor Yellow
kubectl cp scripts/configure-vault.sh vault/vault-0:/tmp/configure-vault.sh

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to copy script to Vault pod" -ForegroundColor Red
    exit 1
}

# Execute the configuration script inside the pod
Write-Host "Executing configuration inside Vault pod..." -ForegroundColor Yellow
kubectl exec -n vault vault-0 -- sh /tmp/configure-vault.sh

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Vault configuration completed successfully!" -ForegroundColor Green
}
else {
    Write-Host "❌ Vault configuration failed" -ForegroundColor Red
    exit 1
}
