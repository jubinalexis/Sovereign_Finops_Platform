#!/bin/sh
set -e
export VAULT_TOKEN=root
export VAULT_ADDR=http://127.0.0.1:8200

echo "Configuring Kubernetes Auth..."
vault write auth/kubernetes/config kubernetes_host="https://kubernetes.default.svc:443"

echo "Writing Policy..."
vault policy write eso-policy - <<EOH
path "secret/*" {
  capabilities = ["read", "list"]
}
EOH
echo "Done."
