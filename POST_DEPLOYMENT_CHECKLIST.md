# Post-Deployment Checklist

Complete these steps to finalize the Vault deployment.

## Section 1: Cloudflare DNS Configuration

- [ ] Login to Cloudflare Dashboard: https://dash.cloudflare.com
- [ ] Select zone: zazagaby.online (cb7a80048171e671bd14e7ba2ead0623)
- [ ] Go to DNS → Records
- [ ] Add new record:
  - Type: CNAME
  - Name: vault
  - Target: 8678fb1a-f34e-4e90-b961-8151ffe8d051.cfargotunnel.com
  - TTL: Auto (or 120 for testing)
  - Proxy status: Proxied (Orange cloud)
- [ ] Save the record
- [ ] Wait for DNS propagation (usually < 60 seconds)
- [ ] Verify DNS resolves: `dig vault.zazagaby.online`

## Section 2: Verify Vault Access

- [ ] Open browser and navigate to: https://vault.zazagaby.online
- [ ] Verify Cloudflare Access prompt appears
- [ ] Login with email: fazaasro@gmail.com or gabriela.servitya@gmail.com
- [ ] Enter OTP code from email
- [ ] Verify Vault UI loads
- [ ] Login to Vault UI using root token from `.vault-keys.txt`
- [ ] Verify you can see the "secret/" path with 2 secrets

## Section 3: Backup Critical Security Data

### Unseal Keys Backup
- [ ] Open: `/home/ai-dev/swarm/repos/vault-infrastructure/.vault-keys.txt`
- [ ] Copy all 5 unseal keys + root token
- [ ] Store securely in password manager (1Password, Bitwarden, etc.)
- [ ] Label: "Vault Unseal Keys - vault.zazagaby.online"
- [ ] Distribute unseal keys among trusted team members:
  - [ ] Key 1 → Person A
  - [ ] Key 2 → Person B
  - [ ] Key 3 → Person C
  - [ ] Key 4 → Person D
  - [ ] Key 5 → Person E

### AppRole Credentials Backup
- [ ] Open: `/home/ai-dev/swarm/repos/vault-infrastructure/.vault-approle.txt`
- [ ] Copy Role ID and Secret ID
- [ ] Store in password manager
- [ ] Label: "Vault GitHub Actions AppRole"

## Section 4: GitHub Repository Configuration

For each repository that needs Vault access:

### 4.1 Add GitHub Secrets
- [ ] Go to repository: https://github.com/fazaasro/[repo-name]
- [ ] Navigate to: Settings → Secrets and variables → Actions
- [ ] Click "New repository secret"
- [ ] Add VAULT_ADDR:
  - Name: `VAULT_ADDR`
  - Value: `http://vault.zazagaby.online`
  - Click "Add secret"
- [ ] Add VAULT_ROLE_ID:
  - Name: `VAULT_ROLE_ID`
  - Value: `945989a3-d4ad-3a14-99ee-d6e0086d7c71`
  - Click "Add secret"
- [ ] Add VAULT_SECRET_ID:
  - Name: `VAULT_SECRET_ID`
  - Value: `41e44bae-a83d-2914-324d-c657b5df4dad`
  - Click "Add secret"

### 4.2 Test GitHub Actions Workflow
- [ ] Copy workflow from: `.github/workflows/vault-example.yml`
- [ ] Add to repository: `.github/workflows/vault-integration.yml`
- [ ] Trigger workflow manually: Actions → vault-integration → Run workflow
- [ ] Monitor workflow execution
- [ ] Verify secrets are successfully retrieved from Vault
- [ ] Check workflow logs for any errors

## Section 5: Security Verification

### 5.1 Verify Vault is Unsealed
```bash
cd /home/ai-dev/swarm/repos/vault-infrastructure
docker exec vault vault status
```
- [ ] Confirm "Sealed: false"
- [ ] Confirm "Initialized: true"

### 5.2 Verify Secrets are Stored
```bash
export VAULT_TOKEN="<root-token>"
docker exec -e VAULT_TOKEN vault vault kv list secret/
```
- [ ] Confirm "glm-api-key" exists
- [ ] Confirm "cloudflare-api-token" exists

### 5.3 Verify AppRole Authentication
```bash
docker exec vault vault write auth/approle/login \
  role_id="945989a3-d4ad-3a14-99ee-d6e0086d7c71" \
  secret_id="41e44bae-a83d-2914-324d-c657b5df4dad"
```
- [ ] Confirm token is returned
- [ ] Confirm token has correct policies (github-actions)

### 5.4 Verify Cloudflare Access
- [ ] Test with different user accounts
- [ ] Verify OTP flow works
- [ ] Verify session timeout (24h)

## Section 6: Monitoring Setup

### 6.1 Health Check Script
Create `/home/ai-dev/scripts/check-vault.sh`:
```bash
#!/bin/bash
# Vault health check

STATUS=$(docker exec vault vault status -format=json | jq -r '.sealed')
if [ "$STATUS" = "false" ]; then
  echo "✅ Vault is unsealed and healthy"
  exit 0
else
  echo "❌ Vault is sealed or unhealthy"
  exit 1
fi
```
- [ ] Create the script
- [ ] Make executable: `chmod +x /home/ai-dev/scripts/check-vault.sh`
- [ ] Test: `/home/ai-dev/scripts/check-vault.sh`

### 6.2 Add to Existing Monitoring
- [ ] Add vault.zazagaby.online to Portainer monitoring
- [ ] Add health check to Overseer dashboard
- [ ] Configure alert notifications for:
  - Vault sealed status
  - Vault container stopped
  - Cloudflare tunnel disconnected

## Section 7: Backup Configuration

### 7.1 Automated Backup Script
Create `/home/ai-dev/scripts/backup-vault.sh`:
```bash
#!/bin/bash
# Backup Vault data volume

BACKUP_DIR="/home/ai-dev/backups/vault"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

docker run --rm \
  -v vault-infrastructure_vault_data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/vault-data-$DATE.tar.gz -C /data .

# Keep last 7 days
find $BACKUP_DIR -name "vault-data-*.tar.gz" -mtime +7 -delete

echo "Vault backup completed: $BACKUP_DIR/vault-data-$DATE.tar.gz"
```
- [ ] Create backup script
- [ ] Make executable: `chmod +x /home/ai-dev/scripts/backup-vault.sh`
- [ ] Test: `/home/ai-dev/scripts/backup-vault.sh`
- [ ] Verify backup file is created

### 7.2 Schedule Daily Backups
Add to crontab:
```bash
crontab -e
# Add line:
0 2 * * * /home/ai-dev/scripts/backup-vault.sh >> /home/ai-dev/logs/vault-backup.log 2>&1
```
- [ ] Edit crontab: `crontab -e`
- [ ] Add backup cron job
- [ ] Verify schedule: `crontab -l`
- [ ] Test backup runs at next scheduled time

## Section 8: Documentation Updates

- [ ] Update TOOLS.md with Vault information
- [ ] Add Vault section to infrastructure documentation
- [ ] Document unseal procedure for team members
- [ ] Create runbook for common Vault operations
- [ ] Document incident response procedures

## Section 9: Final Verification

- [ ] Vault accessible via https://vault.zazagaby.online
- [ ] Cloudflare Access SSO working
- [ ] GitHub Actions can retrieve secrets
- [ ] Backup automation configured
- [ ] Monitoring enabled
- [ ] Documentation updated
- [ ] Unseal keys secured
- [ ] Team members trained

## Section 10: Sign-Off

- [ ] Deployment verified by: _________________
- [ ] Date: _________________
- [ ] Notes: ___________________________________
- [ ] Outstanding issues: ______________________

---

**After completing this checklist:**
- Delete this file or move to archive
- Confirm all critical steps are complete
- Document any deviations or issues
- Schedule follow-up review in 7 days

**Questions or Issues:**
- Check VAULT_SETUP.md for troubleshooting
- Review Vault logs: `docker compose logs vault`
- Review cloudflared logs: `sudo journalctl -u cloudflared -f`
- Consult HashiCorp Vault documentation: https://developer.hashicorp.com/vault
