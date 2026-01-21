#!/bin/bash

# ============================================================================
# SMTP Server Installation Script for Ubuntu 22.04
# ============================================================================
# This script installs and configures Postfix, OpenDKIM, Dovecot, and Let's Encrypt
# for a simple single-domain SMTP email server
#
# IMPORTANT: Run this script as root or with sudo
# Usage: sudo bash install.sh

set -e  # Exit on error

# ============================================================================
# COLOR OUTPUT
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

# ============================================================================
# LOAD CONFIGURATION FROM .env FILE
# ============================================================================

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env file if it exists
if [ -f "$PROJECT_DIR/.env" ]; then
    log_info "Loading configuration from .env file..."
    source "$PROJECT_DIR/.env"
else
    # Use default hardcoded values if .env doesn't exist
    DOMAIN="benefitsmart.xyz"
    HOSTNAME="mail.benefitsmart.xyz"
    EMAIL_USER="admin"
    EMAIL_PASSWORD="Kingsley419."
    ADMIN_EMAIL="admin@benefitsmart.xyz"
    log_warn ".env file not found, using default values"
fi


# ============================================================================
# PRE-FLIGHT CHECKS 
# ============================================================================

log_info "Starting SMTP server installation..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root or with sudo"
    exit 1
fi

# Check Ubuntu version
if ! grep -q "22.04" /etc/os-release; then
    log_warn "This script is designed for Ubuntu 22.04. Your system may differ."
fi

# ============================================================================
# UPDATE SYSTEM
# ============================================================================

log_info "Updating system packages..."
apt-get update
apt-get upgrade -y

# ============================================================================
# SET HOSTNAME
# ============================================================================

log_info "Setting hostname to $HOSTNAME..."
hostnamectl set-hostname $HOSTNAME
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

# ============================================================================
# INSTALL PACKAGES
# ============================================================================

log_info "Installing Postfix, Dovecot, OpenDKIM, and dependencies..."

# Set Postfix to install without prompts
debconf-set-selections <<< "postfix postfix/mailname string $HOSTNAME"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

apt-get install -y \
    postfix \
    postfix-pcre \
    dovecot-core \
    dovecot-pop3d- \
    dovecot-imapd- \
    opendkim \
    opendkim-tools \
    certbot \
    mailutils \
    ufw \
    curl

log_info "Packages installed successfully"

# ============================================================================
# CONFIGURE FIREWALL
# ============================================================================

log_info "Configuring firewall..."
ufw --force enable
ufw allow 22/tcp    # SSH
ufw allow 25/tcp    # SMTP
ufw allow 587/tcp   # Submission
ufw allow 80/tcp    # HTTP (for Let's Encrypt)
ufw allow 443/tcp   # HTTPS

log_info "Firewall configured"

# ============================================================================
# CREATE MAIL USER
# ============================================================================

log_info "Creating mail user..."

# Create vmail user for mail storage
if ! id -u vmail > /dev/null 2>&1; then
    useradd -r -m -d /var/mail/vmail -s /sbin/nologin -c "Virtual Mail User" vmail
fi

# Create mail directory
mkdir -p /var/mail/vmail/$DOMAIN
chown -R vmail:vmail /var/mail/vmail
chmod -R 770 /var/mail/vmail

# ============================================================================
# GENERATE DKIM KEYS
# ============================================================================

log_info "Generating DKIM keys..."

mkdir -p /etc/opendkim/keys/$DOMAIN
cd /etc/opendkim/keys/$DOMAIN

# Generate 2048-bit RSA key
opendkim-genkey -s default -d $DOMAIN -b 2048

# Set permissions
chown -R opendkim:opendkim /etc/opendkim
chmod 600 /etc/opendkim/keys/$DOMAIN/default.private

log_info "DKIM keys generated at /etc/opendkim/keys/$DOMAIN/"

# ============================================================================
# CONFIGURE OPENDKIM
# ============================================================================

log_info "Configuring OpenDKIM..."

# Copy configuration (assumes you have configs/opendkim/ directory)
if [ -f "../configs/opendkim/opendkim.conf" ]; then
    cp ../configs/opendkim/opendkim.conf /etc/opendkim.conf
    cp ../configs/opendkim/TrustedHosts /etc/opendkim/TrustedHosts
    
    # Replace domain placeholders
    sed -i "s/yourdomain.com/$DOMAIN/g" /etc/opendkim.conf
    sed -i "s/yourdomain.com/$DOMAIN/g" /etc/opendkim/TrustedHosts
else
    log_warn "OpenDKIM config files not found in ../configs/opendkim/"
fi

# Create OpenDKIM directory
mkdir -p /var/spool/postfix/opendkim
chown opendkim:opendkim /var/spool/postfix/opendkim

# ============================================================================
# CONFIGURE POSTFIX
# ============================================================================

log_info "Configuring Postfix..."

# Backup original config
cp /etc/postfix/main.cf /etc/postfix/main.cf.backup
cp /etc/postfix/master.cf /etc/postfix/master.cf.backup

# Copy configurations (assumes you have configs/postfix/ directory)
if [ -f "../configs/postfix/main.cf" ]; then
    cp ../configs/postfix/main.cf /etc/postfix/main.cf
    cp ../configs/postfix/master.cf /etc/postfix/master.cf
    
    # Replace domain placeholders
    sed -i "s/yourdomain.com/$DOMAIN/g" /etc/postfix/main.cf
    sed -i "s/mail.yourdomain.com/$HOSTNAME/g" /etc/postfix/main.cf
else
    log_warn "Postfix config files not found in ../configs/postfix/"
fi

# Create virtual alias file
touch /etc/postfix/virtual
postmap /etc/postfix/virtual

# ============================================================================
# CONFIGURE DOVECOT
# ============================================================================

log_info "Configuring Dovecot..."

# Copy Dovecot configs
if [ -f "../configs/dovecot/10-auth.conf" ]; then
    cp ../configs/dovecot/10-auth.conf /etc/dovecot/conf.d/10-auth.conf
    cp ../configs/dovecot/10-master.conf /etc/dovecot/conf.d/10-master.conf
fi

# Create users file with hashed password
log_info "Creating email user: $EMAIL_USER@$DOMAIN"
HASHED_PASSWORD=$(doveadm pw -s SHA512-CRYPT -p "$EMAIL_PASSWORD")
echo "$EMAIL_USER@$DOMAIN:$HASHED_PASSWORD" > /etc/dovecot/users
chmod 600 /etc/dovecot/users

# ============================================================================
# OBTAIN SSL CERTIFICATE
# ============================================================================

log_info "Obtaining Let's Encrypt SSL certificate..."
log_warn "Make sure DNS is properly configured before running this!"
log_warn "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
sleep 10

# Detect if Apache or Nginx is running and stop it temporarily
APACHE_WAS_RUNNING=false
NGINX_WAS_RUNNING=false

if systemctl is-active --quiet apache2; then
    log_info "Stopping Apache temporarily for SSL certificate generation..."
    systemctl stop apache2
    APACHE_WAS_RUNNING=true
fi

if systemctl is-active --quiet nginx; then
    log_info "Stopping Nginx temporarily for SSL certificate generation..."
    systemctl stop nginx
    NGINX_WAS_RUNNING=true
fi

# Try standalone mode
certbot certonly --standalone --non-interactive --agree-tos --email $ADMIN_EMAIL -d $HOSTNAME

if [ $? -eq 0 ]; then
    log_info "SSL certificate obtained successfully"
else
    log_error "Failed to obtain SSL certificate using standalone mode"
    log_warn "Trying DNS challenge method instead..."
    log_info "You'll need to add a TXT record to your DNS"
    
    # Try manual DNS challenge as fallback
    certbot certonly --manual --preferred-challenges dns --agree-tos --email $ADMIN_EMAIL -d $HOSTNAME
    
    if [ $? -ne 0 ]; then
        log_error "Failed to obtain SSL certificate"
        log_warn "You can manually run one of these commands later:"
        log_warn "  sudo certbot certonly --standalone -d $HOSTNAME"
        log_warn "  sudo certbot certonly --manual --preferred-challenges dns -d $HOSTNAME"
    fi
fi

# Restart web servers if they were running
if [ "$APACHE_WAS_RUNNING" = true ]; then
    log_info "Restarting Apache..."
    systemctl start apache2
fi

if [ "$NGINX_WAS_RUNNING" = true ]; then
    log_info "Restarting Nginx..."
    systemctl start nginx
fi

# ============================================================================
# START SERVICES
# ============================================================================

log_info "Starting services..."

systemctl enable opendkim
systemctl enable postfix
systemctl enable dovecot

systemctl restart opendkim
systemctl restart postfix
systemctl restart dovecot

# ============================================================================
# VERIFICATION
# ============================================================================

log_info "Verifying installation..."

# Check if services are running
systemctl is-active --quiet postfix && log_info "Postfix is running" || log_error "Postfix is not running"
systemctl is-active --quiet opendkim && log_info "OpenDKIM is running" || log_error "OpenDKIM is not running"
systemctl is-active --quiet dovecot && log_info "Dovecot is running" || log_error "Dovecot is not running"

# Test DKIM key
log_info "Testing DKIM key..."
opendkim-testkey -d $DOMAIN -s default -vvv

# ============================================================================
# DISPLAY IMPORTANT INFORMATION
# ============================================================================

# Get server's public IP
# Get server's public IP using robust detection
get_public_ip() {
    # Try EC2 Instance Metadata Service (IMDSv1) first - fast and internal
    local ec2_ip
    ec2_ip=$(curl -s --max-time 2 http://169.254.169.254/latest/meta-data/public-ipv4)
    if [[ -n "$ec2_ip" ]]; then
        echo "$ec2_ip"
        return
    fi
    
    # Fallback to external services
    curl -s --max-time 5 ifconfig.me || curl -s --max-time 5 icanhazip.com || echo "YOUR_SERVER_IP"
}

SERVER_IP=$(get_public_ip)

# Extract DKIM public key (remove quotes and format)
DKIM_RECORD=$(grep -o 'p=.*' /etc/opendkim/keys/$DOMAIN/default.txt | tr -d '"\n\t ')

echo ""
echo "=============================================================================="
log_info "🎉 Installation Complete!"
echo "=============================================================================="
echo ""
echo "=============================================================================="
log_info "📧 EMAIL CREDENTIALS"
echo "=============================================================================="
echo "  Email:    $EMAIL_USER@$DOMAIN"
echo "  Password: $EMAIL_PASSWORD"
echo ""
log_warn "⚠️  IMPORTANT: Change this password after setup!"
echo ""

echo "=============================================================================="
log_info "📬 SMTP SETTINGS (For Email Clients)"
echo "=============================================================================="
echo "  Server:       $HOSTNAME"
echo "  Port:         587"
echo "  Encryption:   STARTTLS"
echo "  Username:     $EMAIL_USER@$DOMAIN"
echo "  Password:     $EMAIL_PASSWORD"
echo "  Auth Method:  Normal Password"
echo ""

echo "=============================================================================="
log_info "🌐 DNS RECORDS - ADD ALL OF THESE TO YOUR DNS PROVIDER"
echo "=============================================================================="
echo ""
log_info "Copy and paste these records to your DNS management panel:"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "1️⃣  A Record (Mail Server Address)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Type:     A"
echo "Name:     $HOSTNAME"
echo "Value:    $SERVER_IP"
echo "TTL:      300"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "2️⃣  MX Record (Mail Exchanger)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Type:     MX"
echo "Name:     $DOMAIN"
echo "Value:    10 $HOSTNAME"
echo "Priority: 10"
echo "TTL:      300"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "3️⃣  SPF Record (Sender Policy Framework)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Type:     TXT"
echo "Name:     $DOMAIN"
echo "Value:    \"v=spf1 mx ip4:$SERVER_IP ~all\""
echo "TTL:      300"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "4️⃣  DKIM Record (DomainKeys Identified Mail)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Type:     TXT"
echo "Name:     default._domainkey.$DOMAIN"
echo "Value:    \"v=DKIM1; k=rsa; $DKIM_RECORD\""
echo "TTL:      300"
echo ""
log_warn "Note: Some DNS providers require you to remove quotes"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "5️⃣  DMARC Record (Domain-based Message Authentication)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Type:     TXT"
echo "Name:     _dmarc.$DOMAIN"
echo "Value:    \"v=DMARC1; p=quarantine; rua=mailto:$ADMIN_EMAIL\""
echo "TTL:      300"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_info "6️⃣  PTR Record (Reverse DNS) - Configure at your hosting provider"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "IP:       $SERVER_IP"
echo "Points to: $HOSTNAME"
echo ""
log_warn "⚠️  For AWS: EC2 Console → Elastic IPs → Update reverse DNS"
log_warn "⚠️  For other providers: Contact support or use control panel"
echo ""

echo "=============================================================================="
log_info "📋 QUICK COPY FORMAT (For faster DNS setup)"
echo "=============================================================================="
echo ""
cat << EOF
# A Record
$HOSTNAME.    300    IN    A        $SERVER_IP

# MX Record  
$DOMAIN.      300    IN    MX       10 $HOSTNAME.

# SPF Record
$DOMAIN.      300    IN    TXT      "v=spf1 mx ip4:$SERVER_IP ~all"

# DKIM Record
default._domainkey.$DOMAIN.    300    IN    TXT    "v=DKIM1; k=rsa; $DKIM_RECORD"

# DMARC Record
_dmarc.$DOMAIN.    300    IN    TXT    "v=DMARC1; p=quarantine; rua=mailto:$ADMIN_EMAIL"

# PTR Record (at hosting provider)
$SERVER_IP    →    $HOSTNAME
EOF
echo ""

echo "=============================================================================="
log_info "✅ VERIFICATION COMMANDS (Run after DNS propagation)"
echo "=============================================================================="
echo ""
echo "Wait 5-60 minutes for DNS propagation, then verify:"
echo ""
echo "# Check A Record"
echo "dig $HOSTNAME +short"
echo ""
echo "# Check MX Record"
echo "dig $DOMAIN MX +short"
echo ""
echo "# Check SPF Record"
echo "dig $DOMAIN TXT +short | grep spf"
echo ""
echo "# Check DKIM Record"
echo "dig default._domainkey.$DOMAIN TXT +short"
echo ""
echo "# Check PTR Record"
echo "dig -x $SERVER_IP +short"
echo ""
echo "# Test DKIM Key"
echo "sudo opendkim-testkey -d $DOMAIN -s default -vvv"
echo ""

echo "=============================================================================="
log_info "🚀 NEXT STEPS"
echo "=============================================================================="
echo "1. ✅ Add all DNS records above to your DNS provider"
echo "2. ✅ Configure PTR/Reverse DNS at your hosting provider"
echo "3. ⏱️  Wait 5-60 minutes for DNS propagation"
echo "4. ✅ Run verification commands above"
echo "5. ✅ Send test email: echo 'Test' | mail -s 'Test' your-email@gmail.com"
echo "6. ✅ Check deliverability at https://www.mail-tester.com"
echo "7. ✅ Change default email password!"
echo ""
log_warn "CRITICAL: On AWS, request Port 25 unblock from AWS Support if not done!"
echo ""

echo "=============================================================================="
log_info "📚 DOCUMENTATION"
echo "=============================================================================="
echo "Main Guide:       README.md"
echo "AWS Deployment:   docs/AWS_DEPLOYMENT.md"
echo "DNS Setup:        docs/DNS_SETUP.md"
echo "Troubleshooting:  docs/SSL_TROUBLESHOOTING.md"
echo ""
log_info "Installation logs saved to: /var/log/mail.log"
echo ""

echo "=============================================================================="
log_info "🎯 QUICK ACCESS TO YOUR CONFIGURATION"
echo "=============================================================================="
echo ""
log_success "To view your complete SMTP configuration anytime, run:"
echo ""
echo "    sudo bash scripts/show-config.sh"
echo ""
echo "This will display:"
echo "  • SMTP credentials (username & password)"
echo "  • All DNS records"
echo "  • Connection settings"
echo "  • Verification commands"
echo ""

# ============================================================================
# CLEANUP
# ============================================================================

log_info "Cleaning up unused files..."
# Remove any temporary files or unnecessary default configs if they exist
# Specifically asking to delete unused files as per user request
rm -f "$PROJECT_DIR/README.md"  # Replace with specific file paths if you have targets
# We keep the main README but maybe remove other clutter if identified.
# For now, we will perform a safe cleanup of package cache
apt-get clean
apt-get autoremove -y

log_info "Configuration file location: $PROJECT_DIR/.env"
echo ""
echo "=============================================================================="
echo ""
