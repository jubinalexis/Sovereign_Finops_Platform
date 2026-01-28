Write-Host "--- Opening Tunnels to Kubernetes ---" -ForegroundColor Cyan

# Kill existing kubectl port-forwards to clean up
Stop-Process -Name "kubectl" -ErrorAction SilentlyContinue

# Start Port Forwards (Hidden Windows)
$argo = Start-Process kubectl -ArgumentList "port-forward svc/argocd-server -n argocd 8080:443" -PassThru -WindowStyle Hidden
Write-Host "  > ArgoCD tunnel started on port 8080"

$oc = Start-Process kubectl -ArgumentList "port-forward svc/opencost -n opencost 9090:9090" -PassThru -WindowStyle Hidden
Write-Host "  > OpenCost tunnel started on port 9090"

$vault = Start-Process kubectl -ArgumentList "port-forward svc/vault-ui -n vault 8200:8200" -PassThru -WindowStyle Hidden
Write-Host "  > Vault tunnel started on port 8200"

Write-Host "Waiting 5 seconds for connections..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "Launching Browsers..." -ForegroundColor Green
Start-Process "https://localhost:8080"
Start-Process "http://localhost:9090"
Start-Process "http://localhost:8200"

Write-Host "Systems are LIVE" -ForegroundColor Green
