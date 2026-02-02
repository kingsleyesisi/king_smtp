# Kings SMTP Relay

A simple, send-only SMTP relay setup for `mail.benefitsmart.xyz`.

## Quick Start

1. **Setup**
   ```bash
   sudo bash setup.sh
   ```
   This installs Postfix, configures SASL auth, and generates DKIM keys.

2. **Get DNS Records** (Easy!)
   ```bash
   bash get-dns.sh
   ```
   This generates `cloudflare_dns.txt` with all records ready to copy.

3. **Verify DNS**
   After adding DNS records, wait 5-60 minutes then verify:
   ```bash
   sudo bash scripts/verify-dns.sh
   ```

4. **Test Email**
   ```bash
   sudo bash scripts/test-email.sh
   ```

## Configuration

| Setting | Value |
|---------|-------|
| Server IP | `3.215.252.135` |
| Hostname | `mail.benefitsmart.xyz` |
| SMTP Port | `587` (STARTTLS) |
| Username | `admin@benefitsmart.xyz` |

Configuration is stored in `.env`. Run `bash scripts/show-config.sh` to view all settings.

## Documentation

- [AWS Deployment](docs/AWS_DEPLOYMENT.md)
- [DNS Setup Guide](docs/DNS_SETUP.md)
- [SSL Troubleshooting](docs/SSL_TROUBLESHOOTING.md)

