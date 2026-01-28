#!/bin/sh
# Vault Configuration Script for Kubernetes Integration
# Configures Kubernetes auth, policies, and secrets for External Secrets Operator

set -e

export VAULT_TOKEN=root
export VAULT_ADDR=http://127.0.0.1:8200

echo "=== Vault Configuration for Sovereign FinOps Platform ==="

# Read Kubernetes credentials from service account
echo "Reading Kubernetes credentials..."
KUBE_CA_CERT=$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)
KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
KUBE_HOST="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT}"

# Enable Kubernetes Auth
echo "Enabling Kubernetes authentication method..."
vault auth enable kubernetes 2>/dev/null || echo "Kubernetes auth already enabled"

# Configure Kubernetes Auth with CA cert and token
echo "Configuring Kubernetes authentication..."
vault write auth/kubernetes/config \
    kubernetes_host="$KUBE_HOST" \
    kubernetes_ca_cert="$KUBE_CA_CERT" \
    token_reviewer_jwt="$KUBE_TOKEN"

# Create Policy for External Secrets Operator
echo "Creating ESO policy..."
vault policy write eso-policy - <<EOH
path "secret/*" {
  capabilities = ["read", "list"]
}
EOH

# Create Role for external-secrets ServiceAccount
echo "Creating Kubernetes auth role for External Secrets..."
vault write auth/kubernetes/role/external-secrets-role \
    bound_service_account_names=external-secrets \
    bound_service_account_namespaces=external-secrets \
    policies=eso-policy \
    ttl=24h

# Create test secret
echo "Creating test secret..."
vault kv put secret/finops-db-creds \
    username=admin \
    password=supersecret

echo "=== Configuration Complete ==="
echo "Verifying Kubernetes auth configuration..."
vault read auth/kubernetes/config

echo ""
echo "✅ Vault is ready for External Secrets Operator integration"
