Write-Host "🔄 Restauration des connexions..." -ForegroundColor Cyan

# 1. Nettoyage des vieux tunnels
Stop-Process -Name "kubectl" -ErrorAction SilentlyContinue

# 2. Récupération du nom exact du pod ArgoCD
$podArgs = kubectl get pod -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath="{.items[0].metadata.name}"

if (-not $podArgs) {
    Write-Host "❌ Erreur: Impossible de trouver le pod ArgoCD !" -ForegroundColor Red
    exit
}

Write-Host "✅ Pod ArgoCD détecté : $podArgs" -ForegroundColor Green

# 3. Lancement des tunnels (Fenêtres séparées pour voir les erreurs)
# ArgoCD sur le port 8888 (pour éviter les conflits du 8080)
Start-Process kubectl -ArgumentList "port-forward pod/$podArgs -n argocd 8888:8080"
Write-Host "  > ArgoCD lancé sur le port 8888 (Attendez que la fenêtre indique 'Forwarding...')"

# OpenCost sur 9090
Start-Process kubectl -ArgumentList "port-forward svc/opencost -n opencost 9090:9090" -WindowStyle Hidden
Write-Host "  > OpenCost lancé sur le port 9090 (Mode Hidden)"

# Vault sur 8200
Start-Process kubectl -ArgumentList "port-forward svc/vault-ui -n vault 8200:8200" -WindowStyle Hidden
Write-Host "  > Vault lancé sur le port 8200 (Mode Hidden)"

Write-Host "`n⏳ Attente de 5 secondes..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 4. Ouverture des navigateurs
Write-Host "🚀 Ouverture des pages..." -ForegroundColor Cyan
Start-Process "https://localhost:8888"
Start-Process "http://localhost:9090"
Start-Process "http://localhost:8200/ui"

Write-Host "`n⚠️  IMPORTANT :" -ForegroundColor Yellow
Write-Host "1. Ne fermez pas la fenêtre noire 'kubectl' qui s'est ouverte."
Write-Host "2. Pour ArgoCD, utilisez bien https://localhost:8888"
