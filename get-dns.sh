#!/bin/bash

# ============================================================================
# Quick DNS Records Generator for Cloudflare
# ============================================================================
# Usage: bash get-dns.sh
# Output: cloudflare_dns.txt (ready to copy-paste into Cloudflare)

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load .env
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "ERROR: .env file not found in $SCRIPT_DIR"
    exit 1
fi

# Use hardcoded IP from .env or detect
SERVER_IP="${SERVER_IP:-3.215.252.135}"

# Get DKIM record if available
if [ -f "/etc/opendkim/keys/$DOMAIN/default.txt" ]; then
    DKIM_RECORD=$(sudo cat /etc/opendkim/keys/$DOMAIN/default.txt 2>/dev/null | grep -o 'p=.*' | tr -d '"
	 ')
    if [ -z "$DKIM_RECORD" ]; then
        DKIM_RECORD="[RUN SETUP FIRST TO GENERATE DKIM KEY]"
    fi
else
    DKIM_RECORD="[RUN SETUP FIRST TO GENERATE DKIM KEY]"
fi

OUTPUT_FILE="$SCRIPT_DIR/cloudflare_dns.txt"

# Generate the file
cat <<EOF > "$OUTPUT_FILE"
================================================================================
CLOUDFLARE DNS RECORDS FOR $DOMAIN
================================================================================
Server IP: $SERVER_IP (Elastic IP)
Generated: $(date)
================================================================================

COPY THESE INTO CLOUDFLARE DNS SETTINGS:

┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. A RECORD (Mail Server)                                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│ Type:     A                                                                 │
│ Name:     mail                                                              │
│ IPv4:     $SERVER_IP
│ Proxy:    DNS Only (Gray Cloud) ← IMPORTANT!                               │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. MX RECORD (Mail Exchanger)                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│ Type:     MX                                                                │
│ Name:     @                                                                 │
│ Server:   mail.$DOMAIN
│ Priority: 10                                                                │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 3. SPF RECORD (Sender Policy Framework)                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│ Type:     TXT                                                               │
│ Name:     @                                                                 │
│ Content:  v=spf1 mx ip4:$SERVER_IP ~all
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 4. DKIM RECORD (DomainKeys Identified Mail)                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│ Type:     TXT                                                               │
│ Name:     default._domainkey                                                │
│ Content:  v=DKIM1; k=rsa; $DKIM_RECORD
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 5. DMARC RECORD (Domain-based Message Authentication)                       │
├─────────────────────────────────────────────────────────────────────────────┤
│ Type:     TXT                                                               │
│ Name:     _dmarc                                                            │
│ Content:  v=DMARC1; p=quarantine; rua=mailto:$ADMIN_EMAIL
└─────────────────────────────────────────────────────────────────────────────┘

================================================================================
AWS REVERSE DNS (PTR) - Must be done in AWS Console, NOT Cloudflare
================================================================================
1. Go to AWS EC2 Console → Elastic IPs
2. Select $SERVER_IP
3. Actions → Update reverse DNS
4. Enter: $HOSTNAME

================================================================================
EOF

# Display to console
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo "  DNS Records for $DOMAIN"
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "  Server IP: $SERVER_IP"
echo "  Hostname:  $HOSTNAME"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
echo ""
echo "  ✅ Full DNS records saved to: $OUTPUT_FILE"
echo ""
echo "  Quick copy - open the file:"
echo "    cat $OUTPUT_FILE"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════"
