kubectl exec -i vault-0 -n vault -- sh <<EOF
export VAULT_TOKEN=root
export VAULT_ADDR=http://127.0.0.1:8200

# Enable Kubernetes Auth
vault auth enable kubernetes || true

# Config Kubernetes Auth
vault write auth/kubernetes/config \
    kubernetes_host="https://\${KUBERNETES_PORT_443_TCP_ADDR}:443"

# Create Policy
vault policy write eso-policy - <<EOH
path "secret/*" {
  capabilities = ["read", "list"]
}
EOH

# Create Role
vault write auth/kubernetes/role/external-secrets-role \
    bound_service_account_names=external-secrets \
    bound_service_account_namespaces=external-secrets \
    policies=eso-policy \
    ttl=24h

# Create a test secret (KV v2 is default in dev mode usually, but check mount)
# In dev mode, secret/ is usually enabled as kv-v2.
vault kv put secret/finops-db-creds username=admin password=supersecret
EOF
