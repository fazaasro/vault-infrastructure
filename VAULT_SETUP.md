# Vault Setup Documentation

## Overview

This document describes the setup of HashiCorp Vault for secrets management at vault.zazagaby.online, integrated with GitHub Actions.

## Infrastructure Details

- **Public URL:** vault.zazagaby.online
- **Internal Address:** 127.0.0.1:8200
- **Tunnel ID:** 8678fb1a-f34e-4e90-b961-8151ffe8d051
- **Vault Version:** v1.21.3
- **Storage:** File-based (Docker volume)

## Architecture

```
GitHub Actions
    ↓ (AppRole auth)
Cloudflare Tunnel (SSL/TLS)
    ↓
Cloudflare Access (SSO)
    ↓
Vault (127.0.0.1:8200)
    ↓
Secrets (KV v2)
```

## Quick Start

### 1. Check Vault Status

```bash
cd /home/ai-dev/swarm/repos/vault-infrastructure
docker exec vault vault status
```

### 2. Unseal Vault (if sealed)

Vault needs 3 of 5 unseal keys:

```bash
# Unseal with 3 keys
docker exec vault vault operator unseal <key1>
docker exec vault vault operator unseal <key2>
docker exec vault vault operator unseal <key3>
```

Keys are stored in `.vault-keys.txt` (SECURE FILE - DO NOT COMMIT!)

### 3. Access Vault UI

Navigate to: https://vault.zazagaby.online

Login with root token from `.vault-keys.txt`

## Vault Management

### Starting/Stopping Vault

```bash
# Start Vault
cd /home/ai-dev/swarm/repos/vault-infrastructure
docker compose up -d

# Stop Vault
docker compose down

# View logs
docker compose logs -f vault

# Restart Vault
docker compose restart
```

### Managing Secrets

```bash
# Set VAULT_ADDR and VAULT_TOKEN
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="<root-token-from-vault-keys.txt>"

# List secrets
docker exec -e VAULT_ADDR -e VAULT_TOKEN vault vault kv list secret/

# Read a secret
docker exec -e VAULT_ADDR -e VAULT_TOKEN vault vault kv get secret/glm-api-key

# Create/Update a secret
docker exec -e VAULT_ADDR -e VAULT_TOKEN vault vault kv put secret/my-secret key1=value1 key2=value2

# Delete a secret
docker exec -e VAULT_ADDR -e VAULT_TOKEN vault vault kv delete secret/my-secret
```

### AppRole Management

```bash
# View AppRole details
docker exec vault vault read auth/approle/role/github-actions

# Generate new Secret ID
docker exec vault vault write -f auth/approle/role/github-actions/secret-id

# Get Role ID
docker exec vault vault read auth/approle/role/github-actions/role-id
```

## Cloudflare Configuration

### DNS CNAME Record

Create a CNAME record in Cloudflare DNS:

- **Name:** vault
- **Type:** CNAME
- **Target:** 8678fb1a-f34e-4e90-b961-8151ffe8d051.cfargotunnel.com
- **Proxy:** Yes (Cloudflare Access enabled)

### Cloudflare Tunnel Configuration

The tunnel is configured in `~/.config/cloudflared/config.yml`:

```yaml
ingress:
  - hostname: vault.zazagaby.online
    service: http://127.0.0.1:8200
    originRequest:
      noTLSVerify: true
```

Restart cloudflared after config changes:

```bash
sudo systemctl restart cloudflared
sudo systemctl status cloudflared
```

### Cloudflare Access (SSO)

Vault is protected by Cloudflare Access with the "ZG" access group:
- Allowed users: fazaasro@gmail.com, gabriela.servitya@gmail.com
- Authentication: Email OTP
- Session duration: 24 hours

## GitHub Actions Integration

### Required GitHub Secrets

Add these secrets to your GitHub repository settings:

1. **VAULT_ADDR:** `http://vault.zazagaby.online`
2. **VAULT_ROLE_ID:** `945989a3-d4ad-3a14-99ee-d6e0086d7c71`
3. **VAULT_SECRET_ID:** `41e44bae-a83d-2914-324d-c657b5df4dad`

### Example Workflow

See `.github/workflows/vault-example.yml` for a complete example.

Basic usage:

```yaml
- name: Authenticate with Vault
  id: vault-auth
  run: |
    VAULT_TOKEN=$(vault write -field=token auth/approle/login \
      role_id="${{ secrets.VAULT_ROLE_ID }}" \
      secret_id="${{ secrets.VAULT_SECRET_ID }}")
    echo "VAULT_TOKEN=$VAULT_TOKEN" >> $GITHUB_OUTPUT

- name: Get secret from Vault
  run: |
    GLM_API_KEY=$(vault kv get -field=api_key secret/glm-api-key)
    echo "GLM_API_KEY=$GLM_API_KEY" >> $GITHUB_ENV
```

Or use the official action:

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

## Security Considerations

### Unseal Keys

- **Location:** `.vault-keys.txt`
- **Shares:** 5 keys
- **Threshold:** 3 keys needed to unseal
- **Backup:** Store securely in password manager
- **Distribution:** Split among trusted team members

### Root Token

- **Location:** `.vault-keys.txt`
- **Usage:** Only for initial setup and emergency
- **Recommendation:** Rotate periodically
- **Never:** Commit to version control

### AppRole Credentials

- **Role ID:** Less sensitive (can be public)
- **Secret ID:** Must be kept secret (GitHub secret)
- **Policy:** Restrictive (read-only access to specific secrets)
- **Rotation:** Can rotate Secret ID without affecting Role ID

### Access Layers

1. **Cloudflare Access:** SSO (email OTP)
2. **Vault Auth:** AppRole (for CI/CD)
3. **Vault Policies:** Least privilege access
4. **Secret Encryption:** Vault's built-in encryption

## Disaster Recovery

### Backup Vault Data

```bash
# Stop Vault
docker compose down

# Backup volume
docker run --rm -v vault-infrastructure_vault_data:/data -v $(pwd):/backup alpine tar czf /backup/vault-data-backup-$(date +%Y%m%d).tar.gz -C /data .

# Start Vault
docker compose up -d
```

### Restore Vault Data

```bash
# Stop Vault
docker compose down

# Restore volume
docker run --rm -v vault-infrastructure_vault_data:/data -v $(pwd):/backup alpine tar xzf /backup/vault-data-backup-YYYYMMDD.tar.gz -C /data

# Start Vault (will need unsealing)
docker compose up -d
```

### Unseal After Restart

After any restart, Vault will be sealed and require unsealing:

```bash
docker exec vault vault operator unseal <key1>
docker exec vault vault operator unseal <key2>
docker exec vault vault operator unseal <key3>
```

## Monitoring

### Health Check

```bash
# Check if Vault is running
curl -s http://127.0.0.1:8200/v1/sys/health

# Check status
docker exec vault vault status
```

### Logs

```bash
# View Vault logs
docker logs -f vault

# View cloudflared logs
sudo journalctl -u cloudflared -f
```

## Troubleshooting

### Vault won't start

```bash
# Check logs
docker compose logs vault

# Check volume permissions
docker exec vault ls -la /vault/data

# Fix permissions if needed
docker exec vault chown -R vault:vault /vault/data
```

### Cannot access vault.zazagaby.online

```bash
# Check if Vault is running
curl http://127.0.0.1:8200

# Check cloudflared status
sudo systemctl status cloudflared

# Check cloudflared logs
sudo journalctl -u cloudflared -n 50

# Test DNS
dig vault.zazagaby.online
```

### GitHub Actions cannot access Vault

1. Check VAULT_ADDR is correct
2. Verify VAULT_ROLE_ID and VAULT_SECRET_ID
3. Check AppRole policy permissions
4. Test authentication locally:
   ```bash
   vault write auth/approle/login \
     role_id=<ROLE_ID> \
     secret_id=<SECRET_ID>
   ```

## File Structure

```
/home/ai-dev/swarm/repos/vault-infrastructure/
├── docker-compose.yml              # Vault container definition
├── config/
│   ├── vault-config.hcl           # Vault server config
│   └── github-actions-policy.hcl  # AppRole policy
├── .github/
│   └── workflows/
│       └── vault-example.yml      # GitHub Actions example
├── .vault-keys.txt                # UNSEAL KEYS (SECURE!)
├── .vault-approle.txt             # AppRole credentials
└── VAULT_SETUP.md                 # This file
```

## Next Steps

1. **Backup Unseal Keys:** Store `.vault-keys.txt` in password manager
2. **Configure DNS:** Add CNAME record for vault.zazagaby.online
3. **Add GitHub Secrets:** VAULT_ROLE_ID and VAULT_SECRET_ID to repos
4. **Test Access:** Verify UI is accessible via Cloudflare Access
5. **Test CI/CD:** Run example workflow to verify integration
6. **Schedule Backups:** Automate Vault data backups
7. **Monitor:** Set up health checks and alerting

## Support

For issues or questions:
- Vault Documentation: https://developer.hashicorp.com/vault
- Cloudflare Tunnel Docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps
- AppRole Method: https://developer.hashicorp.com/vault/docs/auth/approle

---

**Last Updated:** 2026-02-19
**Maintained by:** AI Assistant
