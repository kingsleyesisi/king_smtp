# Kings SMTP Server - Quick Reference

## Installation Complete! ✅

### SMTP Credentials (Use in Your Application)

```
Host:       mail.benefitsmart.xyz
Port:       587
Username:   admin@benefitsmart.xyz
Password:   Kingsley419.
Encryption: STARTTLS (TLS)
Auth:       Normal Password / PLAIN
```

### DNS Records

See [`DNS_RECORDS.txt`](file:///home/king/projects/test/kings_smtp/DNS_RECORDS.txt) for copy-paste DNS records

### Quick Commands

```bash
# View complete configuration
sudo bash scripts/show-config.sh

# Verify DNS is configured
sudo bash scripts/verify-dns.sh

# Send test email to kingsleyesisi1@gmail.com
sudo bash scripts/test-email.sh

# Check mail logs
sudo tail -f /var/log/mail.log

# Check mail queue
mailq

# View service status
sudo systemctl status postfix opendkim dovecot
```

### Important Files

- **DNS_RECORDS.txt** - Copy these to Cloudflare
- **CLOUDFLARE_SETUP.txt** - Detailed Cloudflare instructions
- **.env** - Configuration file (credentials stored here)

### Next Steps

1. Add DNS records to Cloudflare (from DNS_RECORDS.txt)
2. Configure PTR in AWS EC2 Console
3. Wait 5-60 minutes
4. Run: `sudo bash scripts/verify-dns.sh`
5. Test: `sudo bash scripts/test-email.sh`

### Support

Check logs: `sudo tail -f /var/log/mail.log`
