#!/bin/bash

# ============================================================================
# Generate Cloudflare DNS File
# ============================================================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="$PROJECT_DIR/cloudflare_dns.txt"

# Load .env
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
else
    echo "ERROR: .env file not found."
    exit 1
fi

# Ensure SERVER_IP is set (it should be in .env, but fallback just in case)
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(curl -s ifconfig.me)
fi

# Get DKIM record
if [ -f "/etc/opendkim/keys/$DOMAIN/default.txt" ]; then
    DKIM_RECORD=$(sudo cat /etc/opendkim/keys/$DOMAIN/default.txt | grep -o 'p=.*' | tr -d '"\n\t ')
else
    DKIM_RECORD="[DKIM KEY NOT GENERATED YET - RUN SETUP FIRST]"
fi

# Generate the file
cat <<EOF > "$OUTPUT_FILE"
===============================================================================
CLOUDFLARE DNS RECORDS FOR $DOMAIN
===============================================================================
Server IP: $SERVER_IP (Elastic IP)
===============================================================================

COPY AND PASTE THESE RECORD DETAILS INTO CLOUDFLARE:

Record 1 (A Record):
Type:     A
Name:     mail
IPv4:     $SERVER_IP
Proxy:    DNS Only (Gray Cloud)

Record 2 (MX Record):
Type:     MX
Name:     @
Mail Server: mail.$DOMAIN
Priority: 10

Record 3 (SPF Record):
Type:     TXT
Name:     @
Content:  v=spf1 mx ip4:$SERVER_IP ~all

Record 4 (DKIM Record):
Type:     TXT
Name:     default._domainkey
Content:  v=DKIM1; k=rsa; $DKIM_RECORD

Record 5 (DMARC Record):
Type:     TXT
Name:     _dmarc
Content:  v=DMARC1; p=quarantine; rua=mailto:$ADMIN_EMAIL

===============================================================================
REMINDER: AWS REVERSE DNS (PTR)
===============================================================================
You usually CANNOT do this in Cloudflare. You must do it in AWS Console.
1. Go to AWS EC2 Console -> Elastic IPs
2. Select $SERVER_IP
3. Actions -> Update reverse DNS
4. Enter: $HOSTNAME
===============================================================================
EOF

echo "DNS records generated at: $OUTPUT_FILE"
