# Policy for GitHub Actions
# Allows read access to specific secrets

# Read access to GLM API key
path "secret/data/glm-api-key" {
  capabilities = ["read"]
}

# Read access to Cloudflare API token
path "secret/data/cloudflare-api-token" {
  capabilities = ["read"]
}

# List access to secrets
path "secret/metadata/*" {
  capabilities = ["list"]
}
