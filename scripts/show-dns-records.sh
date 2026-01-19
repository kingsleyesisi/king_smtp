#!/bin/bash

# ============================================================================
# DNS Records Display Script
# ============================================================================
# This script displays all DNS records needed for your SMTP server
# Run this anytime to see what DNS records you need to configure
#
# Usage: sudo bash show-dns-records.sh

set -e

# ============================================================================
# CONFIGURATION - Must match your install.sh settings
# ============================================================================

DOMAIN="benefitsmart.xyz"
HOSTNAME="mail.benefitsmart.xyz"
ADMIN_EMAIL="admin@benefitsmart.xyz"

# ============================================================================
# COLOR OUTPUT
# ============================================================================

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

# ============================================================================
# GET SERVER INFO
# ============================================================================

# Get server's public IP
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || hostname -I | awk '{print $1}')

# Check if DKIM key exists
if [ -f "/etc/opendkim/keys/$DOMAIN/default.txt" ]; then
    # Extract DKIM public key (remove quotes and format)
    DKIM_RECORD=$(grep -o 'p=.*' /etc/opendkim/keys/$DOMAIN/default.txt | tr -d '"\n\t ')
else
    DKIM_RECORD="DKIM_KEY_NOT_GENERATED_YET"
    log_warn "DKIM key not found. Run installation first!"
fi

# ============================================================================
# DISPLAY DNS RECORDS
# ============================================================================

echo ""
echo "=============================================================================="
log_info "🌐 DNS RECORDS FOR $DOMAIN"
echo "=============================================================================="
echo ""
log_info "Server IP: $SERVER_IP"
log_info "Hostname:  $HOSTNAME"
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
if [ "$DKIM_RECORD" = "DKIM_KEY_NOT_GENERATED_YET" ]; then
    log_warn "⚠️  DKIM key not found! Run the installation script first."
else
    log_info "✅ DKIM key loaded successfully"
fi
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
log_info "📋 QUICK COPY FORMAT"
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
log_info "📚 DNS PROVIDER GUIDES"
echo "=============================================================================="
echo ""
echo "Route 53 (AWS):    docs/DNS_SETUP.md"
echo "Cloudflare:        docs/DNS_SETUP.md"
echo "Other providers:   docs/DNS_SETUP.md"
echo ""
echo "=============================================================================="
echo ""
