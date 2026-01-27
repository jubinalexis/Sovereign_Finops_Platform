Write-Host "=== 1. Checking Node Status ===" -ForegroundColor Cyan
kubectl get nodes

Write-Host "`n=== 2. Checking ArgoCD Applications ===" -ForegroundColor Cyan
kubectl get applications -n argocd

Write-Host "`n=== 3. Checking Critical Pods (Non-Running) ===" -ForegroundColor Cyan
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded

Write-Host "`n=== 4. Checking Secrets Integration ===" -ForegroundColor Cyan
Write-Host "Fetching 'finops-db-creds-k8s' from 'external-secrets' namespace..."
$secret = kubectl get secret finops-db-creds-k8s -n external-secrets --ignore-not-found
if ($secret) {
    Write-Host "✅ Secret exists." -ForegroundColor Green
    $username = kubectl get secret finops-db-creds-k8s -n external-secrets -o jsonpath='{.data.username}'
    $password = kubectl get secret finops-db-creds-k8s -n external-secrets -o jsonpath='{.data.password}'
    
    # Decode Base64 (PowerShell friendly)
    $usernameDecoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($username))
    $passwordDecoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($password))
    
    Write-Host "Username: $usernameDecoded"
    Write-Host "Password: $passwordDecoded"
} else {
    Write-Host "❌ Secret NOT found." -ForegroundColor Red
}

Write-Host "`n=== 5. Access Info ===" -ForegroundColor Cyan
$argocdPwd = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'
$argocdPwdDecoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($argocdPwd))

Write-Host "ArgoCD UI: https://localhost:8080 (admin / $argocdPwdDecoded)"
Write-Host "OpenCost: http://localhost:9090"
Write-Host "Vault UI: http://localhost:8200 (Token: root)"
