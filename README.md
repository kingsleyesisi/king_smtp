# Kings SMTP - Self-Hosted Email Server

A complete, production-ready SMTP email server setup for Ubuntu 22.04 using Postfix, OpenDKIM, Dovecot, and Let's Encrypt SSL certificates.

## 📋 Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [AWS Deployment Guide](#aws-deployment-guide)
- [DNS Configuration](#dns-configuration)
- [Manual Installation](#manual-installation)
- [Configuration Files](#configuration-files)
- [Testing Your Mail Server](#testing-your-mail-server)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)
- [Maintenance](#maintenance)

## ✨ Features

- **Postfix** - Reliable SMTP mail server
- **OpenDKIM** - DKIM signing for email authentication
- **Dovecot** - Secure IMAP/POP3 delivery
- **Let's Encrypt** - Free SSL/TLS certificates
- **Automatic firewall configuration**
- **Ready for production use**

## 🔧 Prerequisites

### Local/VPS Requirements
- Ubuntu 22.04 LTS server
- Root or sudo access
- At least 1GB RAM
- 20GB disk space
- Public IP address
- Domain name with DNS access

### AWS Specific Requirements
- AWS Account
- EC2 instance (t2.micro or larger)
- Elastic IP address
- Route 53 or external DNS provider
- Port 25 unblocked (requires AWS support request)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd kings_smtp
```

### 2. Configure Variables

Edit `scripts/install.sh` and update these variables:

```bash
DOMAIN="yourdomain.com"
HOSTNAME="mail.yourdomain.com"
EMAIL_USER="admin"
EMAIL_PASSWORD="your-secure-password"
ADMIN_EMAIL="admin@yourdomain.com"
```

### 3. Run Installation

```bash
sudo bash scripts/install.sh
```

The script will:
- Install all required packages
- Configure firewall rules
- Generate DKIM keys
- Set up Postfix, OpenDKIM, and Dovecot
- Obtain Let's Encrypt SSL certificate
- Start all services
- **Display all DNS records in one convenient output**

### 4. View DNS Records Anytime

After installation (or anytime later), you can display all required DNS records:

```bash
sudo bash scripts/show-dns-records.sh
```

This script shows:
- A, MX, SPF, DKIM, DMARC, PTR records
- Copy-friendly format for your DNS provider
- Verification commands
- Current configuration details

## ☁️ AWS Deployment Guide

### Step 1: Launch EC2 Instance

#### 1.1 Create EC2 Instance

1. Log in to AWS Console → EC2 Dashboard
2. Click **Launch Instance**
3. Configure instance:
   - **Name**: `mail-server` or similar
   - **AMI**: Ubuntu 22.04 LTS (Free tier eligible)
   - **Instance Type**: `t2.small` (minimum) or `t2.medium` (recommended)
     - ⚠️ `t2.micro` may be too limited for a mail server
   - **Key Pair**: Create or select existing key pair (required for SSH access)

#### 1.2 Configure Network Settings

1. **VPC**: Default VPC (or create custom VPC)
2. **Auto-assign Public IP**: Enable
3. **Security Group**: Create new or use existing with these rules:

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | Your IP | SSH access |
| SMTP | TCP | 25 | 0.0.0.0/0 | Incoming email |
| Submission | TCP | 587 | 0.0.0.0/0 | Outgoing email (STARTTLS) |
| HTTP | TCP | 80 | 0.0.0.0/0 | Let's Encrypt verification |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Optional (web management) |
| IMAP | TCP | 993 | Your IP | Optional (secure IMAP) |

4. **Storage**: 20GB gp3 SSD (minimum), 30GB recommended

#### 1.3 Allocate Elastic IP

> ⚠️ **CRITICAL**: Email servers require a static IP address

1. In EC2 Console → **Elastic IPs**
2. Click **Allocate Elastic IP address**
3. Click **Allocate**
4. Select the new Elastic IP → **Actions** → **Associate Elastic IP address**
5. Select your instance → **Associate**

**Note your Elastic IP** - you'll need it for DNS configuration.

### Step 2: Request Port 25 Unblocking

> ⚠️ **IMPORTANT**: AWS blocks port 25 by default to prevent spam

1. Go to **AWS Support Center**
2. Create a new case:
   - **Case Type**: Service Limit Increase
   - **Limit Type**: EC2 Instances
   - **Select**: Email Port 25 Throttle Removal
3. Fill the form:
   - **Elastic IP**: Your Elastic IP address
   - **Use Case**: Transactional email server for [your domain]
   - **Reverse DNS**: mail.yourdomain.com
4. Submit request

⏱️ **Processing Time**: Usually 24-48 hours

### Step 3: Configure DNS Records

#### 3.1 Using AWS Route 53

1. **Create Hosted Zone** (if not exists):
   ```
   Domain name: yourdomain.com
   ```

2. **Add DNS Records**:

```
# A Record - Mail server
Type: A
Name: mail.yourdomain.com
Value: YOUR_ELASTIC_IP
TTL: 300

# MX Record - Mail exchanger
Type: MX
Name: yourdomain.com
Value: 10 mail.yourdomain.com
TTL: 300

# SPF Record - Sender Policy Framework
Type: TXT
Name: yourdomain.com
Value: "v=spf1 mx ip4:YOUR_ELASTIC_IP ~all"
TTL: 300

# DMARC Record - Email authentication
Type: TXT
Name: _dmarc.yourdomain.com
Value: "v=DMARC1; p=quarantine; rua=mailto:admin@yourdomain.com"
TTL: 300
```

**DKIM Record** - Will be added after installation (Step 5)

#### 3.2 Using External DNS Provider (Cloudflare, Namecheap, etc.)

Add the same records as above to your DNS provider's control panel.

### Step 4: Configure Reverse DNS (PTR Record)

> ⚠️ **CRITICAL**: Many mail servers reject emails without proper reverse DNS

1. Go to **EC2 Console** → **Elastic IPs**
2. Select your Elastic IP
3. **Actions** → **Update reverse DNS**
4. Enter: `mail.yourdomain.com`
5. **Update**

**Verify PTR Record**:
```bash
dig -x YOUR_ELASTIC_IP +short
# Should return: mail.yourdomain.com
```

### Step 5: Connect and Install

#### 5.1 SSH into Instance

```bash
# Add read permissions to your key file
chmod 400 your-key.pem

# Connect to instance
ssh -i your-key.pem ubuntu@YOUR_ELASTIC_IP
```

#### 5.2 Update System

```bash
sudo apt update && sudo apt upgrade -y
```

#### 5.3 Clone Repository

```bash
cd ~
git clone <your-repo-url> kings_smtp
cd kings_smtp
```

#### 5.4 Configure Installation Script

Edit the configuration variables:

```bash
nano scripts/install.sh
```

Update these values:
```bash
DOMAIN="yourdomain.com"
HOSTNAME="mail.yourdomain.com"
EMAIL_USER="admin"
EMAIL_PASSWORD="CHANGE_THIS_SECURE_PASSWORD"
ADMIN_EMAIL="admin@yourdomain.com"
```

Save with `Ctrl+X`, then `Y`, then `Enter`

#### 5.5 Run Installation

```bash
sudo bash scripts/install.sh
```

⏱️ **Installation Time**: 5-10 minutes

### Step 6: Add DKIM DNS Record

After installation completes, the script will display your DKIM public key:

```
default._domainkey IN TXT ( "v=DKIM1; k=rsa; p=MIIBIjANBgkq..." )
```

Add this to your DNS:

**Route 53**:
```
Type: TXT
Name: default._domainkey.yourdomain.com
Value: "v=DKIM1; k=rsa; p=MIIBIjANBgkq..."
TTL: 300
```

**Note**: Remove quotes and parentheses, keep only the content.

### Step 7: Verify Installation

#### 7.1 Check Services

```bash
sudo systemctl status postfix
sudo systemctl status opendkim
sudo systemctl status dovecot
```

All should show **active (running)** in green.

#### 7.2 Test DKIM

```bash
sudo opendkim-testkey -d yourdomain.com -s default -vvv
```

Should show: `key OK`

## 📧 DNS Configuration

### Required DNS Records

| Record Type | Name | Value | Priority | TTL |
|-------------|------|-------|----------|-----|
| A | mail.yourdomain.com | YOUR_SERVER_IP | - | 300 |
| MX | yourdomain.com | mail.yourdomain.com | 10 | 300 |
| TXT (SPF) | yourdomain.com | v=spf1 mx ip4:YOUR_IP ~all | - | 300 |
| TXT (DKIM) | default._domainkey | v=DKIM1; k=rsa; p=YOUR_KEY | - | 300 |
| TXT (DMARC) | _dmarc | v=DMARC1; p=quarantine; rua=mailto:admin@yourdomain.com | - | 300 |
| PTR | YOUR_IP | mail.yourdomain.com | - | 300 |

### DNS Propagation

Wait 5-60 minutes for DNS propagation. Check status:

```bash
# Check MX record
dig yourdomain.com MX +short

# Check SPF record
dig yourdomain.com TXT +short

# Check DKIM record
dig default._domainkey.yourdomain.com TXT +short

# Check PTR/reverse DNS
dig -x YOUR_IP +short
```

## 🔍 Testing Your Mail Server

### Test 1: Send Test Email

```bash
echo "Test email body" | mail -s "Test Subject" recipient@example.com
```

Check `/var/log/mail.log` for delivery status:

```bash
sudo tail -f /var/log/mail.log
```

### Test 2: SMTP Connection

```bash
telnet mail.yourdomain.com 587
```

You should see:
```
220 mail.yourdomain.com ESMTP Postfix
```

Type `QUIT` to exit.

### Test 3: Email Deliverability

Send a test email to these services:

1. **Mail Tester**: https://www.mail-tester.com
   - Send email to the provided address
   - Check your score (aim for 10/10)

2. **Gmail**: Send to your Gmail account
   - Check if it lands in inbox (not spam)
   - View original message → Check SPF, DKIM, DMARC pass

### Test 4: STARTTLS Encryption

```bash
openssl s_client -starttls smtp -connect mail.yourdomain.com:587
```

Should show SSL certificate details.

## 🛠️ Manual Installation

If you prefer step-by-step manual installation instead of the automated script:

### 1. Install Packages

```bash
sudo apt update
sudo apt install -y postfix postfix-pcre dovecot-core dovecot-imapd \
  dovecot-lmtpd opendkim opendkim-tools certbot mailutils
```

### 2. Configure Postfix

Copy and edit configuration files from `configs/postfix/`:

```bash
sudo cp configs/postfix/main.cf /etc/postfix/main.cf
sudo cp configs/postfix/master.cf /etc/postfix/master.cf

# Replace placeholders
sudo sed -i 's/yourdomain.com/YOURDOMAIN/g' /etc/postfix/main.cf
sudo sed -i 's/mail.yourdomain.com/YOURHOSTNAME/g' /etc/postfix/main.cf
```

### 3. Configure OpenDKIM

```bash
# Generate keys
sudo mkdir -p /etc/opendkim/keys/yourdomain.com
cd /etc/opendkim/keys/yourdomain.com
sudo opendkim-genkey -s default -d yourdomain.com -b 2048
sudo chown -R opendkim:opendkim /etc/opendkim

# Copy configs
sudo cp configs/opendkim/opendkim.conf /etc/opendkim.conf
sudo cp configs/opendkim/TrustedHosts /etc/opendkim/TrustedHosts
```

### 4. Configure Dovecot

```bash
sudo cp configs/dovecot/10-auth.conf /etc/dovecot/conf.d/10-auth.conf
sudo cp configs/dovecot/10-master.conf /etc/dovecot/conf.d/10-master.conf
```

### 5. Obtain SSL Certificate

```bash
sudo certbot certonly --standalone -d mail.yourdomain.com
```

### 6. Start Services

```bash
sudo systemctl enable postfix opendkim dovecot
sudo systemctl restart postfix opendkim dovecot
```

## 📁 Configuration Files

### Postfix (`configs/postfix/`)

- **main.cf**: Main Postfix configuration
  - SMTP settings
  - TLS/SSL configuration
  - SMTP authentication
  - Virtual aliases

- **master.cf**: Postfix service definitions
  - Submission port (587)
  - SMTP daemon settings

### OpenDKIM (`configs/opendkim/`)

- **opendkim.conf**: DKIM signing configuration
- **TrustedHosts**: Trusted relay hosts

### Dovecot (`configs/dovecot/`)

- **10-auth.conf**: Authentication settings
- **10-master.conf**: Service listeners

## 🐛 Troubleshooting

### Issue: Port 25 Blocked on AWS

**Symptom**: Emails not being delivered

**Solution**:
1. Submit AWS support request (Step 2 in AWS guide)
2. Wait for approval (24-48 hours)
3. Test with: `telnet yourdomain.com 25`

### Issue: SSL Certificate Error

**Symptom**: Certbot fails with port 80 error

**Solution** (Fixed in updated script):
```bash
# Stop web server temporarily
sudo systemctl stop apache2  # or nginx

# Get certificate
sudo certbot certonly --standalone -d mail.yourdomain.com

# Restart web server
sudo systemctl start apache2  # or nginx
```

**Alternative - DNS Challenge**:
```bash
sudo certbot certonly --manual --preferred-challenges dns -d mail.yourdomain.com
```

### Issue: DKIM Test Fails

**Symptom**: `opendkim-testkey` shows errors

**Solutions**:
1. **Wait for DNS propagation** (up to 24 hours)
2. **Check DNS record format**:
   ```bash
   dig default._domainkey.yourdomain.com TXT +short
   ```
3. **Verify permissions**:
   ```bash
   sudo chown -R opendkim:opendkim /etc/opendkim
   sudo chmod 600 /etc/opendkim/keys/*/default.private
   ```

### Issue: Emails Going to Spam

**Possible Causes**:
1. **Missing SPF/DKIM/DMARC** - Check DNS records
2. **No reverse DNS** - Configure PTR record
3. **Blacklisted IP** - Check at https://mxtoolbox.com/blacklists.aspx
4. **Low reputation** - New servers need to warm up

**Solutions**:
1. Verify all DNS records are correct
2. Send low volume initially (10-20 emails/day)
3. Request delisting if blacklisted
4. Use Email authentication (SPF, DKIM, DMARC)

### Issue: Can't Send Email

**Check logs**:
```bash
sudo tail -f /var/log/mail.log
```

**Test SMTP auth**:
```bash
# Generate base64 credentials
echo -n 'admin@yourdomain.com' | base64
echo -n 'your-password' | base64

# Test with telnet
telnet mail.yourdomain.com 587
EHLO localhost
AUTH LOGIN
[paste base64 email]
[paste base64 password]
```

### Issue: Services Won't Start

**Check status**:
```bash
sudo systemctl status postfix
sudo systemctl status opendkim
sudo systemctl status dovecot
```

**View detailed logs**:
```bash
sudo journalctl -u postfix -n 50
sudo journalctl -u opendkim -n 50
sudo journalctl -u dovecot -n 50
```

**Common fixes**:
```bash
# Check config syntax
sudo postfix check

# Restart services
sudo systemctl restart postfix opendkim dovecot
```

## 🔒 Security Best Practices

### 1. Change Default Password

```bash
# Generate strong password
openssl rand -base64 32

# Update user password
sudo doveadm pw -s SHA512-CRYPT -p 'your-new-password'
# Copy output and update /etc/dovecot/users
```

### 2. Configure Firewall

The install script configures UFW automatically. Verify:

```bash
sudo ufw status
```

### 3. Enable Fail2Ban (Recommended)

```bash
sudo apt install -y fail2ban

# Create jail for Postfix
sudo nano /etc/fail2ban/jail.local
```

Add:
```ini
[postfix]
enabled = true
port = smtp,submission
filter = postfix
logpath = /var/log/mail.log
maxretry = 3
bantime = 3600
```

```bash
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
```

### 4. Regular Updates

```bash
# Auto-updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### 5. Monitor Logs

```bash
# Watch mail logs
sudo tail -f /var/log/mail.log

# Check for auth failures
sudo grep 'authentication failed' /var/log/mail.log
```

### 6. SSL Certificate Renewal

Let's Encrypt certificates expire in 90 days. Auto-renewal:

```bash
# Test renewal
sudo certbot renew --dry-run

# Setup auto-renewal (already configured by certbot)
sudo systemctl status certbot.timer
```

## 🔄 Maintenance

### Update SSL Certificates

Certbot automatically renews certificates. Manual renewal:

```bash
sudo certbot renew
sudo systemctl reload postfix
```

### Backup Configuration

```bash
# Backup script
sudo tar -czf ~/mail-backup-$(date +%Y%m%d).tar.gz \
  /etc/postfix \
  /etc/dovecot \
  /etc/opendkim \
  /etc/letsencrypt

# Backup to S3 (AWS)
aws s3 cp ~/mail-backup-*.tar.gz s3://your-bucket/backups/
```

### Monitor Disk Space

```bash
# Check disk usage
df -h

# Check mail queue
mailq

# Clear old emails (optional)
find /var/mail/vmail -type f -mtime +90 -delete
```

### View Mail Queue

```bash
# Show queued emails
mailq

# View specific message
sudo postcat -q QUEUE_ID

# Delete from queue
sudo postsuper -d QUEUE_ID
```

### Performance Monitoring

```bash
# Check connections
sudo netstat -tuln | grep -E ':(25|587|993)'

# Monitor resources
htop

# CloudWatch (AWS)
# Install CloudWatch agent for detailed metrics
```

## 📚 Additional Resources

- [Postfix Documentation](http://www.postfix.org/documentation.html)
- [OpenDKIM Configuration](http://opendkim.org/opendkim.conf.5.html)
- [Dovecot Wiki](https://wiki.dovecot.org/)
- [Let's Encrypt Docs](https://letsencrypt.org/docs/)
- [AWS Email Setup Guide](https://docs.aws.amazon.com/ses/latest/dg/Welcome.html)
- [Email Deliverability Best Practices](https://www.validity.com/resource-center/email-deliverability-best-practices/)

## 📝 License

[Add your license here]

## 🤝 Contributing

[Add contribution guidelines]

## 💬 Support

For issues and questions:
- Check [Troubleshooting](#troubleshooting) section
- Review `/var/log/mail.log` for errors
- Open an issue in this repository

---

**⚠️ Important Notes**:
- Always use strong passwords
- Keep your system updated
- Monitor logs regularly
- Follow email sending best practices
- Respect anti-spam regulations (CAN-SPAM, GDPR)
