# AWS EC2 Quick Deployment Guide

**⚡ Fast-track guide for deploying Kings SMTP on AWS**

## Pre-Deployment Checklist

- [ ] AWS Account with billing enabled
- [ ] Domain name registered
- [ ] SSH key pair downloaded (.pem file)
- [ ] Credit card on file (for EC2 charges)

## Step-by-Step Deployment

### 1. Launch EC2 Instance (5 minutes)

```
AWS Console → EC2 → Launch Instance

Instance Configuration:
├── Name: mail-server
├── AMI: Ubuntu 22.04 LTS
├── Type: t2.small (minimum)
├── Key Pair: Create new or select existing
├── Network: Default VPC
├── Auto-assign Public IP: ✓ Enable
└── Storage: 20GB gp3 SSD
```

**Security Group Inbound Rules**:
```
Port 22  (SSH)        - Your IP only
Port 25  (SMTP)       - 0.0.0.0/0
Port 587 (Submission) - 0.0.0.0/0
Port 80  (HTTP)       - 0.0.0.0/0
Port 443 (HTTPS)      - 0.0.0.0/0
```

### 2. Allocate Elastic IP (2 minutes)

```
EC2 → Elastic IPs → Allocate Elastic IP address
→ Associate with your mail-server instance
```

**📝 Note your Elastic IP**: `___.___.___.___ `

### 3. Request Port 25 Unblocking (24-48 hours)

```
AWS Support → Create Case
├── Type: Service Limit Increase
├── Limit: Email Port 25 Throttle Removal
├── Elastic IP: [Your IP]
├── Reverse DNS: mail.benefitsmart.xyz
└── Use Case: Transactional email server
```

⏱️ **Submit and wait for approval email**

### 4. Configure DNS Records (10 minutes)

**Route 53** (or your DNS provider):

```dns
# A Record
mail.benefitsmart.xyz.    300    IN    A        YOUR_ELASTIC_IP

# MX Record
yourdomain.com.         300    IN    MX       10 mail.benefitsmart.xyz.

# SPF Record
yourdomain.com.         300    IN    TXT      "v=spf1 mx ip4:YOUR_ELASTIC_IP ~all"

# DMARC Record
_dmarc.yourdomain.com.  300    IN    TXT      "v=DMARC1; p=quarantine; rua=mailto:admin@yourdomain.com"
```

**⚠️ DKIM Record**: Add after installation (see Step 7)

### 5. Set Reverse DNS / PTR Record (2 minutes)

```
EC2 → Elastic IPs → Select your IP
→ Actions → Update reverse DNS
→ Enter: mail.benefitsmart.xyz
```

**Verify**:
```bash
dig -x YOUR_ELASTIC_IP +short
# Should return: mail.benefitsmart.xyz.
```

### 6. SSH and Install (15 minutes)

#### Connect to server:

```bash
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@YOUR_ELASTIC_IP
```

#### Run installation:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Clone repository
cd ~
git clone <YOUR_REPO_URL> kings_smtp
cd kings_smtp

# Edit configuration
nano scripts/install.sh
```

**Update these lines**:
```bash
DOMAIN="yourdomain.com"              # Your domain
HOSTNAME="mail.benefitsmart.xyz"       # Mail hostname
EMAIL_USER="admin"                   # Email username
EMAIL_PASSWORD="SECURE_PASSWORD_123" # Change this!
ADMIN_EMAIL="admin@yourdomain.com"   # Your email
```

**Run installer**:
```bash
sudo bash scripts/install.sh
```

☕ Wait 5-10 minutes for completion

### 7. Add DKIM DNS Record (5 minutes)

After installation, the script displays your DKIM key:

```
default._domainkey IN TXT ( "v=DKIM1; k=rsa; p=MIIBIjANBgkq..." )
```

**Add to DNS**:
```dns
default._domainkey.yourdomain.com.  300  IN  TXT  "v=DKIM1; k=rsa; p=MIIBIjANBgkq..."
```

### 8. Verify Everything Works (10 minutes)

#### Check services:
```bash
sudo systemctl status postfix opendkim dovecot
# All should show: active (running)
```

#### Test DKIM:
```bash
sudo opendkim-testkey -d yourdomain.com -s default -vvv
# Should show: key OK
```

#### Send test email:
```bash
echo "Testing Kings SMTP" | mail -s "Test Email" your-personal-email@gmail.com
```

#### Check mail log:
```bash
sudo tail -f /var/log/mail.log
```

#### Test deliverability:
1. Visit https://www.mail-tester.com
2. Send email to the provided test address
3. Check your score (aim for 10/10)

### 9. Production Checklist

- [ ] Port 25 unblocked by AWS
- [ ] All DNS records propagated (wait 15-60 min)
- [ ] PTR record configured
- [ ] SSL certificate obtained
- [ ] All services running
- [ ] DKIM test passes
- [ ] Test email delivered to inbox (not spam)
- [ ] Mail-tester.com score ≥ 9/10
- [ ] Password changed from default

## 🎯 Quick Reference Commands

### Monitor logs:
```bash
sudo tail -f /var/log/mail.log
```

### Restart services:
```bash
sudo systemctl restart postfix opendkim dovecot
```

### Check email queue:
```bash
mailq
```

### Test SMTP connection:
```bash
telnet mail.benefitsmart.xyz 587
```

### View service status:
```bash
sudo systemctl status postfix
sudo systemctl status opendkim
sudo systemctl status dovecot
```

### Check DNS propagation:
```bash
dig yourdomain.com MX +short
dig yourdomain.com TXT +short
dig default._domainkey.yourdomain.com TXT +short
dig -x YOUR_IP +short
```

## 💰 AWS Cost Estimate

| Resource | Type | Monthly Cost (USD) |
|----------|------|-------------------|
| EC2 Instance | t2.small | ~$17 |
| Elastic IP | Associated | $0 |
| EBS Storage | 20GB gp3 | ~$2 |
| Data Transfer | 10GB/month | ~$1 |
| **TOTAL** | | **~$20/month** |

💡 **Cost Savings**:
- Use Reserved Instances (-40%)
- Use t3.small instead (-20%)
- Snapshot backups to S3 instead of larger EBS

## ⚠️ Common Issues

### Port 25 Still Blocked
**Symptom**: Emails queued but not delivered  
**Solution**: Wait for AWS support approval (24-48h)

### SSL Certificate Failed
**Symptom**: Certbot port 80 error  
**Solution**: Script now auto-stops Apache/Nginx

### Emails Go to Spam
**Symptom**: Test email in spam folder  
**Solution**: 
1. Check all DNS records are correct
2. Verify PTR record: `dig -x YOUR_IP +short`
3. Wait for IP reputation to build (send low volume initially)
4. Check score: https://www.mail-tester.com

### DKIM Test Fails
**Symptom**: `opendkim-testkey` errors  
**Solution**: Wait 30-60 min for DNS propagation

## 📞 Support Resources

- **AWS Port 25 Request**: AWS Support Center
- **DNS Issues**: Check propagation at https://dnschecker.org
- **Blacklist Check**: https://mxtoolbox.com/blacklists.aspx
- **Deliverability Test**: https://www.mail-tester.com
- **Full Documentation**: See [README.md](README.md)

## 🚀 Next Steps

After successful deployment:

1. **Secure your server**:
   ```bash
   sudo apt install fail2ban
   sudo ufw status
   ```

2. **Set up backups**:
   ```bash
   # Install AWS CLI
   sudo apt install awscli
   
   # Create backup script
   nano ~/backup-mail.sh
   ```

3. **Monitor performance**:
   - Install CloudWatch agent
   - Set up email alerts
   - Monitor disk space

4. **Scale up** (if needed):
   - Upgrade to t3.medium for higher traffic
   - Add more storage if storing emails long-term
   - Implement email archiving

---

**✅ Deployment Complete!**

Your SMTP server is now live at: `mail.benefitsmart.xyz`

Test it by sending an email:
```bash
echo "Hello from Kings SMTP!" | mail -s "First Email" recipient@example.com
```
