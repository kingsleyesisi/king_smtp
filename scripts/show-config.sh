#!/bin/bash

# ============================================================================
# SMTP Configuration Display Script
# ============================================================================
# This script displays your complete SMTP configuration including:
# - SMTP credentials
# - DNS records needed
# - Server connection details
#
# Usage: sudo bash scripts/show-config.sh

set -e

# ============================================================================
# LOAD CONFIGURATION FROM .env FILE
# ============================================================================

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env file if it exists
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
else
    echo "ERROR: .env file not found at $PROJECT_DIR/.env"
    echo "Please create .env file based on .env.example"
    exit 1
fi

# ============================================================================
# COLOR OUTPUT
# ============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

# ============================================================================
# GET SERVER INFO
# ============================================================================

# Get server's public IP (use hardcoded from .env if available, otherwise auto-detect)
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || hostname -I | awk '{print $1}')
fi

# Check if DKIM key exists
if [ -f "/etc/opendkim/keys/$DOMAIN/default.txt" ]; then
    # Extract DKIM public key (remove quotes and format) - using sudo for permission
    DKIM_RECORD=$(sudo cat /etc/opendkim/keys/$DOMAIN/default.txt | grep -o 'p=.*' | tr -d '"\\n\\t ')
    DKIM_STATUS="✅ Generated"
else
    DKIM_RECORD="NOT_GENERATED_YET"
    DKIM_STATUS="❌ Not Found - Run installation first!"
fi

# ============================================================================
# DISPLAY COMPLETE CONFIGURATION
# ============================================================================

clear

echo ""
echo "=============================================================================="
log_success "📧 COMPLETE SMTP SERVER CONFIGURATION"
echo "=============================================================================="
echo ""
echo "Domain:         $DOMAIN"
echo "Hostname:       $HOSTNAME"
echo "Server IP:      $SERVER_IP"
echo "Admin Email:    $ADMIN_EMAIL"
echo ""

echo "=============================================================================="
log_info "🔐 SMTP CREDENTIALS (HARDCODED)"
echo "=============================================================================="
echo ""
echo "  Email Address: ${CYAN}$SMTP_USERNAME${NC}"
echo "  Password:      ${CYAN}$EMAIL_PASSWORD${NC}"
echo ""
log_warn "⚠️  KEEP THESE CREDENTIALS SECURE!"
echo ""

echo "=============================================================================="
log_info "📬 SMTP CONNECTION SETTINGS (For Email Clients/Applications)"
echo "=============================================================================="
echo ""
echo "  SMTP Host:     $SMTP_HOST"
echo "  SMTP Port:     $SMTP_PORT"
echo "  Encryption:    $SMTP_ENCRYPTION"
echo "  Username:      $SMTP_USERNAME"
echo "  Password:      $EMAIL_PASSWORD"
echo "  Auth Method:   Normal Password / PLAIN"
echo ""

echo "=============================================================================="
log_info "🌐 DNS RECORDS TO CONFIGURE"
echo "=============================================================================="
echo ""
log_info "Copy these records to your DNS provider (Route 53, Cloudflare, etc.)"
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
echo "DKIM Status: $DKIM_STATUS"
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
log_info "6️⃣  PTR Record (Reverse DNS)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "IP:        $SERVER_IP"
echo "Points to: $HOSTNAME"
echo ""
log_warn "Configure this at your hosting provider (EC2 Console for AWS)"
echo ""

echo "=============================================================================="
log_info "📋 QUICK COPY FORMAT (For Route 53 / DNS Providers)"
echo "=============================================================================="
echo ""
cat <<EOF
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

# PTR Record (configure at hosting provider)
$SERVER_IP    →    $HOSTNAME
EOF
echo ""

echo "=============================================================================="
log_info "✅ VERIFICATION COMMANDS"
echo "=============================================================================="
echo ""
echo "After adding DNS records, wait 5-60 minutes then run:"
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
echo "# Check DMARC Record"
echo "dig _dmarc.$DOMAIN TXT +short"
echo ""
echo "# Check PTR Record"
echo "dig -x $SERVER_IP +short"
echo ""
echo "# Test DKIM (if installed)"
echo "sudo opendkim-testkey -d $DOMAIN -s default -vvv"
echo ""

echo "=============================================================================="
log_info "🚀 QUICK TEST EMAIL"
echo "=============================================================================="
echo ""
echo "Send test email:"
echo "echo 'Test email from $HOSTNAME' | mail -s 'Test Subject' your-email@gmail.com"
echo ""
echo "Check mail logs:"
echo "sudo tail -f /var/log/mail.log"
echo ""

echo "=============================================================================="
log_info "📚 USEFUL COMMANDS"
echo "=============================================================================="
echo ""
echo "View this config anytime:    sudo bash scripts/show-config.sh"
echo "View DNS records only:       sudo bash scripts/show-dns-records.sh"
echo "Test email sending:          sudo bash scripts/test-email.sh"
echo "Check service status:        sudo systemctl status postfix opendkim dovecot"
echo "View mail logs:              sudo tail -f /var/log/mail.log"
echo ""

echo "=============================================================================="
echo ""
