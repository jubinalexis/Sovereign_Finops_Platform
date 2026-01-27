#!/bin/bash
echo "=== 1. Checking Node Status ==="
kubectl get nodes

echo -e "\n=== 2. Checking ArgoCD Applications ==="
kubectl get applications -n argocd

echo -e "\n=== 3. Checking Critical Pods (Non-Running) ==="
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded

echo -e "\n=== 4. Checking Secrets Integration ==="
echo "Fetching 'finops-db-creds-k8s' from 'external-secrets' namespace..."
if kubectl get secret finops-db-creds-k8s -n external-secrets > /dev/null 2>&1; then
    echo "✅ Secret exists."
    echo "Username: $(kubectl get secret finops-db-creds-k8s -n external-secrets -o jsonpath='{.data.username}' | base64 -d)"
    echo "Password: $(kubectl get secret finops-db-creds-k8s -n external-secrets -o jsonpath='{.data.password}' | base64 -d)"
else
    echo "❌ Secret NOT found."
fi

echo -e "\n=== 5. Access Info ==="
echo "ArgoCD UI: https://localhost:8080 (admin / $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d))"
echo "OpenCost: http://localhost:9090"
echo "Vault UI: http://localhost:8200 (Token: root)"
