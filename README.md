# Vault Infrastructure

HashiCorp Vault deployment for secrets management at vault.zazagaby.online.

## Quick Reference

- **Public URL:** https://vault.zazagaby.online (Cloudflare Access SSO)
- **Internal:** http://127.0.0.1:8200
- **Tunnel:** levy-home-new (8678fb1a-f34e-4e90-b961-8151ffe8d051)

## Status

- ✅ Vault v1.21.3 running
- ✅ Unsealed (3/5 keys)
- ✅ KV secrets engine enabled
- ✅ AppRole configured for GitHub Actions
- ✅ Credentials stored (GLM API, Cloudflare)

## Commands

```bash
# Start/Stop Vault
cd /home/ai-dev/swarm/repos/vault-infrastructure
docker compose up -d    # Start
docker compose down     # Stop
docker compose logs -f  # Logs

# Check status
docker exec vault vault status

# Unseal (if needed)
docker exec vault vault operator unseal <key>

# Access secrets
export VAULT_TOKEN="<root-token>"
docker exec vault vault kv list secret/
```

## Files

| File | Description |
|------|-------------|
| `docker-compose.yml` | Vault container definition |
| `config/vault-config.hcl` | Vault server configuration |
| `config/github-actions-policy.hcl` | AppRole policy for CI/CD |
| `.vault-keys.txt` | ⚠️ UNSEAL KEPS (SECURE!) |
| `.vault-approle.txt` | GitHub Actions credentials |
| `VAULT_SETUP.md` | 📘 Complete setup documentation |
| `.github/workflows/vault-example.yml` | GitHub Actions integration example |

## Security Notes

⚠️ **IMPORTANT:** Never commit `.vault-keys.txt` to version control!

- Unseal keys are stored in `.vault-keys.txt`
- Root token is stored in `.vault-keys.txt`
- Distribute keys among trusted team members
- Store backup in password manager

## GitHub Actions Integration

### Required Secrets (add to repo settings)

```
VAULT_ADDR: http://vault.zazagaby.online
VAULT_ROLE_ID: 945989a3-d4ad-3a14-99ee-d6e0086d7c71
VAULT_SECRET_ID: 41e44bae-a83d-2914-324d-c657b5df4dad
```

### Example Usage

```yaml
- uses: hashicorp/vault-action@v3
  with:
    url: http://vault.zazagaby.online
    method: approle
    roleId: ${{ secrets.VAULT_ROLE_ID }}
    secretId: ${{ secrets.VAULT_SECRET_ID }}
    secrets: |
      secret/data/glm-api-key api_key | GLM_API_KEY
```

See `.github/workflows/vault-example.yml` for complete examples.

## Documentation

📖 See [VAULT_SETUP.md](./VAULT_SETUP.md) for complete documentation including:
- Architecture overview
- Cloudflare configuration
- Secret management
- AppRole setup
- Backup & recovery
- Troubleshooting

## Stored Secrets

Current secrets in Vault:

```
secret/
├── glm-api-key
└── cloudflare-api-token
```

## Architecture

```
┌─────────────────┐
│ GitHub Actions  │
└────────┬────────┘
         │ AppRole auth
┌────────▼────────┐
│ Cloudflare       │
│ Access (SSO)     │
└────────┬────────┘
         │ Tunnel
┌────────▼────────┐
│ Cloudflare       │
│ Tunnel           │
└────────┬────────┘
         │
┌────────▼────────┐
│ Vault           │
│ (127.0.0.1:8200)│
└─────────────────┘
```

---

For detailed setup and configuration, see [VAULT_SETUP.md](./VAULT_SETUP.md).
