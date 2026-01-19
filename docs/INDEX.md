# 📚 Kings SMTP Documentation Index

Welcome to the Kings SMTP server documentation! This guide will help you set up and maintain your self-hosted email server.

## 📖 Documentation Structure

```
kings_smtp/
├── README.md                          # 👈 Start here! Main documentation
└── docs/
    ├── AWS_DEPLOYMENT.md              # ☁️ Quick AWS deployment guide
    ├── SSL_TROUBLESHOOTING.md         # 🔒 Fix SSL certificate issues
    ├── ARCHITECTURE.md                # 📊 System diagrams & architecture
    └── DNS_SETUP.md                   # 🌐 DNS configuration guide
```

## 🚀 Quick Start Paths

### Path 1: New to SMTP Servers?
1. Read the main [README.md](../README.md) - **Features & Prerequisites**
2. Follow [AWS_DEPLOYMENT.md](AWS_DEPLOYMENT.md) - **Step-by-step deployment**
3. Reference [DNS_SETUP.md](DNS_SETUP.md) - **Configure DNS records**
4. Test your setup using [README.md Testing section](../README.md#testing-your-mail-server)

### Path 2: Already Familiar with Email Servers?
1. [AWS_DEPLOYMENT.md](AWS_DEPLOYMENT.md) - **Deploy in 30 minutes**
2. [SSL_TROUBLESHOOTING.md](SSL_TROUBLESHOOTING.md) - **Handle SSL issues**
3. [README.md Verification](../README.md#verification) - **Verify everything works**

### Path 3: Troubleshooting Issues?
1. [SSL_TROUBLESHOOTING.md](SSL_TROUBLESHOOTING.md) - **Port 80 SSL errors**
2. [README.md Troubleshooting](../README.md#troubleshooting) - **Common problems**
3. [ARCHITECTURE.md](ARCHITECTURE.md) - **Understand the system**

## 📄 Document Summaries

### [README.md](../README.md)
**Primary reference for everything**

Topics covered:
- ✨ Feature overview
- 🔧 Prerequisites and requirements
- 🚀 Quick start guide
- ☁️ Complete AWS deployment instructions
- 📧 DNS configuration details
- 🛠️ Manual installation steps
- 🔍 Testing and verification
- 🐛 Troubleshooting common issues
- 🔒 Security best practices
- 🔄 Maintenance procedures

**When to use**: This is your main reference document. Start here for comprehensive information.

---

### [docs/AWS_DEPLOYMENT.md](AWS_DEPLOYMENT.md)
**Fast-track AWS deployment checklist**

Topics covered:
- ⚡ Pre-deployment checklist
- 📋 Step-by-step deployment (30-40 min)
- 💰 Cost estimates (~$20/month)
- 🎯 Quick reference commands
- ⚠️ Common issues and fixes

**When to use**: When deploying to AWS EC2 and want a concise, checklist-style guide.

---

### [docs/SSL_TROUBLESHOOTING.md](SSL_TROUBLESHOOTING.md)
**Complete SSL certificate troubleshooting**

Topics covered:
- 🔴 Port 80 "already in use" error (FIXED in updated script!)
- 🔧 Manual solutions (standalone, webroot, DNS challenge)
- 🐛 Other SSL issues (DNS, rate limits, renewal)
- ✅ Verification commands
- 🔄 Alternative SSL providers

**When to use**: When experiencing SSL certificate errors during installation.

---

### [docs/ARCHITECTURE.md](ARCHITECTURE.md)
**Visual system architecture and diagrams**

Topics covered:
- 🏗️ AWS infrastructure diagram
- 📮 Mail server components
- 🔄 Email flow (sending/receiving)
- 🌐 DNS configuration flow
- 🔒 Security & authentication flow
- 📊 AWS deployment workflow
- 💾 File system structure
- 💰 Cost breakdown

**When to use**: When you want to understand how the system works visually.

---

### [docs/DNS_SETUP.md](DNS_SETUP.md)
**DNS configuration reference**

Topics covered:
- 📝 All required DNS records
- ☁️ Route 53 setup (AWS)
- 🌐 Cloudflare setup
- ✅ DNS verification commands
- 🔍 Troubleshooting DNS issues

**When to use**: When configuring DNS records for your mail server.

---

## 🎯 Common Scenarios

### Scenario: "I want to deploy on AWS EC2"
1. **Read**: [AWS_DEPLOYMENT.md](AWS_DEPLOYMENT.md)
2. **Follow**: Step-by-step checklist
3. **Configure**: DNS using [DNS_SETUP.md](DNS_SETUP.md)
4. **Test**: Using [README.md Testing](../README.md#testing-your-mail-server)

### Scenario: "SSL certificate is failing with port 80 error"
1. **Read**: [SSL_TROUBLESHOOTING.md](SSL_TROUBLESHOOTING.md) - "The Port 80 Problem"
2. **Solution**: Re-run updated `install.sh` (auto-fixes the issue)
3. **Alternative**: Use manual solutions (webroot or DNS challenge)

### Scenario: "Emails going to spam folder"
1. **Check**: [README.md Troubleshooting](../README.md#issue-emails-going-to-spam)
2. **Verify**: DNS records using [DNS_SETUP.md](DNS_SETUP.md)
3. **Test**: Deliverability at https://www.mail-tester.com
4. **Review**: [ARCHITECTURE.md](ARCHITECTURE.md) - Email Deliverability Score

### Scenario: "How does the system work?"
1. **Study**: [ARCHITECTURE.md](ARCHITECTURE.md) - All diagrams
2. **Understand**: Email flow, authentication, DNS
3. **Reference**: [README.md Configuration Files](../README.md#configuration-files)

### Scenario: "Need to set up DNS records"
1. **Guide**: [DNS_SETUP.md](DNS_SETUP.md)
2. **Provider-specific**: Route 53 or Cloudflare sections
3. **Verify**: DNS propagation commands
4. **Troubleshoot**: DNS issues section

## 🔧 Installation Methods

### Method 1: Automated Script (Recommended)
```bash
sudo bash scripts/install.sh
```
- ✅ Installs everything automatically
- ✅ Configures firewall
- ✅ Generates DKIM keys
- ✅ Handles SSL certificates (now with port 80 fix!)
- ✅ Starts all services

**Documentation**: [README.md Quick Start](../README.md#quick-start)

### Method 2: Manual Installation
```bash
# Follow step-by-step manual process
```
- 📋 More control over each step
- 🎓 Better for learning
- 🔧 Useful for custom setups

**Documentation**: [README.md Manual Installation](../README.md#manual-installation)

## 🆘 Getting Help

### 1. Check Documentation
- Issue with SSL? → [SSL_TROUBLESHOOTING.md](SSL_TROUBLESHOOTING.md)
- Issue with DNS? → [DNS_SETUP.md](DNS_SETUP.md)
- General issue? → [README.md Troubleshooting](../README.md#troubleshooting)

### 2. Check Logs
```bash
# Mail server logs
sudo tail -f /var/log/mail.log

# SSL certificate logs
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Service status
sudo systemctl status postfix opendkim dovecot
```

### 3. Verify Configuration
```bash
# Test Postfix config
sudo postfix check

# Test DKIM
sudo opendkim-testkey -d yourdomain.com -s default -vvv

# Check DNS
dig yourdomain.com MX +short
```

### 4. Use Online Tools
- **Mail Tester**: https://www.mail-tester.com (Email deliverability)
- **MXToolbox**: https://mxtoolbox.com (DNS & blacklist check)
- **DNS Checker**: https://dnschecker.org (DNS propagation)
- **SSL Labs**: https://www.ssllabs.com/ssltest/ (SSL/TLS test)

## 📊 System Requirements

### Minimum (Testing)
- 1 GB RAM
- 1 CPU core
- 20 GB storage
- Ubuntu 22.04 LTS

### Recommended (Production)
- 2 GB RAM
- 2 CPU cores
- 30 GB storage
- Ubuntu 22.04 LTS
- Elastic IP (AWS)

See [README.md Prerequisites](../README.md#prerequisites) for details.

## 🗺️ Documentation Roadmap

### Phase 1: Installation ✅ Complete
- [x] Main README
- [x] AWS deployment guide
- [x] SSL troubleshooting
- [x] DNS setup guide
- [x] Architecture diagrams

### Phase 2: Advanced Features (Coming Soon)
- [ ] Webmail integration (Roundcube)
- [ ] Multi-domain support
- [ ] Email forwarding rules
- [ ] Autoresponders
- [ ] Mail filtering (SpamAssassin)

### Phase 3: Monitoring & Automation
- [ ] CloudWatch integration
- [ ] Automated backups
- [ ] Log analysis
- [ ] Performance tuning
- [ ] High availability setup

## 📝 Quick Reference

### Essential Commands

```bash
# Check service status
sudo systemctl status postfix opendkim dovecot

# Restart services
sudo systemctl restart postfix opendkim dovecot

# View logs
sudo tail -f /var/log/mail.log

# Test email sending
echo "Test" | mail -s "Subject" recipient@example.com

# Check email queue
mailq

# Test DKIM
sudo opendkim-testkey -d yourdomain.com -s default -vvv

# Renew SSL certificate
sudo certbot renew

# Check DNS records
dig yourdomain.com MX +short
dig default._domainkey.yourdomain.com TXT +short
```

### Important File Locations

```
/etc/postfix/main.cf                 # Postfix config
/etc/postfix/master.cf               # Postfix services
/etc/opendkim/opendkim.conf          # DKIM config
/etc/opendkim/keys/DOMAIN/           # DKIM keys
/etc/dovecot/conf.d/                 # Dovecot config
/etc/letsencrypt/live/HOSTNAME/      # SSL certificates
/var/mail/vmail/                     # Email storage
/var/log/mail.log                    # Mail logs
```

## 🎓 Learning Resources

### Understanding SMTP
- [RFC 5321 - SMTP](https://tools.ietf.org/html/rfc5321)
- [How Email Works](https://www.youtube.com/watch?v=x28ciavQ4mI)

### Email Authentication
- [DKIM Explained](https://dkim.org/)
- [SPF Record Syntax](https://www.spf-record.com/syntax)
- [DMARC Guide](https://dmarc.org/)

### Software Documentation
- [Postfix Official Docs](http://www.postfix.org/documentation.html)
- [OpenDKIM Documentation](http://opendkim.org/)
- [Dovecot Wiki](https://wiki.dovecot.org/)
- [Let's Encrypt Docs](https://letsencrypt.org/docs/)

## 💡 Pro Tips

1. **Always verify DNS first** - Most email issues are DNS-related
2. **Use mail-tester.com** - Check deliverability before going live
3. **Start with low volume** - Build sender reputation gradually
4. **Monitor logs daily** - Catch issues early
5. **Keep backups** - Backup configs and SSL certificates regularly
6. **Update regularly** - Keep system and packages up to date
7. **Use strong passwords** - Change default passwords immediately
8. **Test before production** - Send test emails to Gmail, Outlook, Yahoo

## 📞 Support Channels

### Official Resources
- **Project Repository**: [GitHub Issues](your-repo-url/issues)
- **Postfix Support**: https://www.postfix.org/support.html
- **Let's Encrypt Forum**: https://community.letsencrypt.org

### Community
- **Stack Overflow**: Tag `postfix`, `opendkim`, `dovecot`
- **Server Fault**: For sysadmin questions
- **AWS Forums**: For AWS-specific issues

## ✅ Post-Installation Checklist

After completing installation, verify:

- [ ] All services running (`systemctl status`)
- [ ] Firewall configured (`ufw status`)
- [ ] DNS records added and propagated
- [ ] PTR/reverse DNS configured
- [ ] SSL certificate obtained
- [ ] DKIM test passes (`opendkim-testkey`)
- [ ] Test email sent successfully
- [ ] Mail-tester.com score ≥ 9/10
- [ ] Emails land in inbox (not spam)
- [ ] Default password changed
- [ ] Backups configured
- [ ] Monitoring set up

See [AWS_DEPLOYMENT.md - Production Checklist](AWS_DEPLOYMENT.md#9-production-checklist) for full list.

---

## 🎉 Success!

Once everything is working:

1. ✅ Your SMTP server is live at `mail.yourdomain.com`
2. ✅ You can send/receive emails
3. ✅ Email authentication (SPF, DKIM, DMARC) is working
4. ✅ SSL/TLS encryption is active
5. ✅ You have a professional email infrastructure

**Next steps**: Set up monitoring, configure backups, and enjoy your self-hosted email!

---

**Last Updated**: January 2026  
**Version**: 1.0.0  
**Status**: Production Ready ✅
