# SSL Certificate Troubleshooting Guide

## The Port 80 Problem (Most Common Issue)

### What Happened?

You saw this error:
```
Could not bind TCP port 80 because it is already in use by another process on
this system (such as a web server). Please stop the program in question and then
try again.
```

### Why It Happens

Let's Encrypt's **standalone mode** needs exclusive access to port 80 to verify domain ownership. If you have Apache, Nginx, or any other web server running, it's already using port 80.

### ✅ Solution (Now Automated)

The updated `install.sh` script **automatically fixes this** by:

1. **Detecting** if Apache or Nginx is running
2. **Stopping** the web server temporarily
3. **Obtaining** the SSL certificate
4. **Restarting** the web server

### How It Works

```bash
# The script now includes this logic:

# Detect if Apache or Nginx is running
APACHE_WAS_RUNNING=false
NGINX_WAS_RUNNING=false

if systemctl is-active --quiet apache2; then
    log_info "Stopping Apache temporarily..."
    systemctl stop apache2
    APACHE_WAS_RUNNING=true
fi

if systemctl is-active --quiet nginx; then
    log_info "Stopping Nginx temporarily..."
    systemctl stop nginx
    NGINX_WAS_RUNNING=true
fi

# Get certificate
certbot certonly --standalone --non-interactive -d mail.yourdomain.com

# Restart web servers if they were running
if [ "$APACHE_WAS_RUNNING" = true ]; then
    systemctl start apache2
fi

if [ "$NGINX_WAS_RUNNING" = true ]; then
    systemctl start nginx
fi
```

## Manual Solutions

If you need to run certbot manually:

### Option 1: Temporarily Stop Web Server

```bash
# For Apache
sudo systemctl stop apache2
sudo certbot certonly --standalone -d mail.yourdomain.com
sudo systemctl start apache2

# For Nginx
sudo systemctl stop nginx
sudo certbot certonly --standalone -d mail.yourdomain.com
sudo systemctl start nginx
```

### Option 2: Use Webroot Plugin (If Web Server Must Stay Running)

```bash
# For Apache
sudo certbot certonly --webroot -w /var/www/html -d mail.yourdomain.com

# For Nginx
sudo certbot certonly --webroot -w /usr/share/nginx/html -d mail.yourdomain.com
```

### Option 3: Use DNS Challenge (No Port 80 Needed)

```bash
sudo certbot certonly --manual --preferred-challenges dns -d mail.yourdomain.com
```

You'll be prompted to add a TXT record to your DNS:

```
_acme-challenge.mail.yourdomain.com.  300  IN  TXT  "random-verification-string"
```

**Steps**:
1. Add the TXT record to your DNS
2. Wait 2-5 minutes for propagation
3. Verify: `dig _acme-challenge.mail.yourdomain.com TXT +short`
4. Press Enter in certbot to continue
5. Certificate will be issued

✅ **Advantage**: Works even if port 80/443 are blocked  
❌ **Disadvantage**: Manual DNS record updates needed for renewal

## Other SSL Issues

### Issue: "Connection Refused" on Port 80

**Symptom**:
```
requests.exceptions.ConnectionError: ('Connection aborted.', ConnectionRefusedError)
```

**Cause**: Firewall blocking port 80

**Solution**:
```bash
# Check if port 80 is open
sudo ufw status

# Open port 80
sudo ufw allow 80/tcp

# Verify
sudo netstat -tuln | grep :80
```

### Issue: DNS Not Propagated

**Symptom**:
```
Detail: DNS problem: NXDOMAIN looking up A for mail.yourdomain.com
```

**Cause**: DNS A record not set or not propagated

**Solution**:
```bash
# Check if A record exists
dig mail.yourdomain.com +short

# If empty, add A record to your DNS:
# mail.yourdomain.com.  300  IN  A  YOUR_SERVER_IP

# Wait 5-15 minutes, then check again
watch -n 10 dig mail.yourdomain.com +short
```

### Issue: Rate Limit Exceeded

**Symptom**:
```
Error: too many certificates already issued for exact set of domains
```

**Cause**: Let's Encrypt limits: 5 duplicate certificates per week

**Solutions**:

1. **Wait 7 days** for the rate limit to reset
2. **Use staging server** for testing:
   ```bash
   sudo certbot certonly --standalone --staging -d mail.yourdomain.com
   ```
3. **Delete failed attempts** don't count against limit
4. **Check your rate limit status**: https://crt.sh/?q=yourdomain.com

### Issue: Certificate Exists but Not Working

**Symptom**: 
```
Certificate obtained but Postfix still shows SSL errors
```

**Cause**: Postfix/Dovecot not configured to use the certificate

**Solution**:

1. **Find certificate location**:
   ```bash
   sudo certbot certificates
   ```
   
   Output shows:
   ```
   Certificate Path: /etc/letsencrypt/live/mail.yourdomain.com/fullchain.pem
   Private Key Path: /etc/letsencrypt/live/mail.yourdomain.com/privkey.pem
   ```

2. **Configure Postfix** (`/etc/postfix/main.cf`):
   ```conf
   smtpd_tls_cert_file=/etc/letsencrypt/live/mail.yourdomain.com/fullchain.pem
   smtpd_tls_key_file=/etc/letsencrypt/live/mail.yourdomain.com/privkey.pem
   ```

3. **Configure Dovecot** (`/etc/dovecot/conf.d/10-ssl.conf`):
   ```conf
   ssl_cert = </etc/letsencrypt/live/mail.yourdomain.com/fullchain.pem
   ssl_key = </etc/letsencrypt/live/mail.yourdomain.com/privkey.pem
   ```

4. **Restart services**:
   ```bash
   sudo systemctl restart postfix
   sudo systemctl restart dovecot
   ```

### Issue: Auto-Renewal Failing

**Symptom**: Certificate expires after 90 days

**Cause**: Renewal process can't bind to port 80

**Solution**: Use a renewal hook

Create `/etc/letsencrypt/renewal-hooks/pre/stop-webserver.sh`:
```bash
#!/bin/bash
systemctl stop apache2 2>/dev/null || true
systemctl stop nginx 2>/dev/null || true
```

Create `/etc/letsencrypt/renewal-hooks/post/start-webserver.sh`:
```bash
#!/bin/bash
systemctl start apache2 2>/dev/null || true
systemctl start nginx 2>/dev/null || true
systemctl reload postfix
systemctl reload dovecot
```

Make executable:
```bash
sudo chmod +x /etc/letsencrypt/renewal-hooks/pre/stop-webserver.sh
sudo chmod +x /etc/letsencrypt/renewal-hooks/post/start-webserver.sh
```

Test renewal:
```bash
sudo certbot renew --dry-run
```

## Verification Commands

### Check Certificate Details
```bash
sudo certbot certificates
```

### Test STARTTLS (Port 587)
```bash
openssl s_client -starttls smtp -connect mail.yourdomain.com:587 -servername mail.yourdomain.com
```

Look for:
```
subject=CN = mail.yourdomain.com
issuer=C = US, O = Let's Encrypt, CN = R3
```

### Test SMTPS (Port 465, if enabled)
```bash
openssl s_client -connect mail.yourdomain.com:465 -servername mail.yourdomain.com
```

### Check Certificate Expiry
```bash
echo | openssl s_client -starttls smtp -connect mail.yourdomain.com:587 2>/dev/null | openssl x509 -noout -dates
```

Output:
```
notBefore=Jan 13 00:00:00 2026 GMT
notAfter=Apr 13 23:59:59 2026 GMT
```

## Alternative SSL Providers

If Let's Encrypt doesn't work for your use case:

### 1. ZeroSSL (Free, like Let's Encrypt)
```bash
# Install acme.sh
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --register-account -m admin@yourdomain.com --server zerossl

# Get certificate
~/.acme.sh/acme.sh --issue --standalone -d mail.yourdomain.com
```

### 2. Self-Signed Certificate (Testing Only)
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/mail-selfsigned.key \
  -out /etc/ssl/certs/mail-selfsigned.crt \
  -subj "/CN=mail.yourdomain.com"
```

⚠️ **Warning**: Self-signed certificates will show warnings in email clients

### 3. Commercial SSL (Namecheap, DigiCert, etc.)
- Purchase certificate for `mail.yourdomain.com`
- Download certificate and private key
- Place in `/etc/ssl/`
- Update Postfix/Dovecot configs

## Best Practices

### 1. Test Before Production
```bash
# Use staging environment for testing
sudo certbot certonly --standalone --staging -d mail.yourdomain.com

# Once working, get real certificate
sudo certbot certonly --standalone -d mail.yourdomain.com
```

### 2. Monitor Certificate Expiry
```bash
# Add to crontab (check weekly)
0 0 * * 0 certbot renew --quiet --deploy-hook "systemctl reload postfix dovecot"
```

### 3. Enable Auto-Renewal
```bash
# Check if timer is active
sudo systemctl status certbot.timer

# Enable if not active
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

### 4. Keep Backups
```bash
# Backup certificates
sudo tar -czf ~/ssl-backup-$(date +%Y%m%d).tar.gz /etc/letsencrypt

# Copy to safe location or S3
aws s3 cp ~/ssl-backup-*.tar.gz s3://your-backup-bucket/
```

## Quick Fix Checklist

When SSL fails, run through this checklist:

- [ ] Is port 80 open in firewall? `sudo ufw status`
- [ ] Is Apache/Nginx stopped? `sudo systemctl status apache2 nginx`
- [ ] Is DNS A record correct? `dig mail.yourdomain.com +short`
- [ ] Is DNS propagated? Wait 15-60 minutes
- [ ] Try DNS challenge instead? `certbot --manual --preferred-challenges dns`
- [ ] Check certbot logs: `sudo tail -f /var/log/letsencrypt/letsencrypt.log`
- [ ] Hit rate limit? Wait 7 days or use staging
- [ ] Try alternative: ZeroSSL or acme.sh

## Getting Help

### View Detailed Logs
```bash
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Increase Verbosity
```bash
sudo certbot --verbose certonly --standalone -d mail.yourdomain.com
```

### Community Support
- Let's Encrypt Community: https://community.letsencrypt.org
- Certbot GitHub: https://github.com/certbot/certbot/issues
- Stack Overflow: Tag `letsencrypt` or `certbot`

---

## Summary

✅ **The updated install.sh script fixes the port 80 issue automatically**

✅ **For manual fixes**: Stop web server → Get cert → Restart web server

✅ **Can't stop web server?**: Use webroot or DNS challenge mode

✅ **Prevention**: Set up renewal hooks to handle web server restarts
