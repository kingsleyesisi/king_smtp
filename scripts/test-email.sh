#!/bin/bash

# ============================================================================
# Test Email Script - Kings SMTP
# ============================================================================
# Sends a test email to verify SMTP server is working
# Usage: sudo bash scripts/test-email.sh

set -e

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env file if it exists
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
fi

# ============================================================================
# EMAIL CONFIGURATION
# ============================================================================

FROM="$EMAIL_USER@$DOMAIN"
TO="kingsleyesisi1@gmail.com"  # Test recipient
SUBJECT="Test Email from Kings SMTP - $(date '+%Y-%m-%d %H:%M:%S')"
BODY="Hello!

This is a test email sent from your Kings SMTP server.

Server Details:
- Domain: $DOMAIN
- Hostname: $HOSTNAME
- From: $FROM
- Sent at: $(date)

If you receive this email, your SMTP server is working correctly!

Best regards,
Kings SMTP Server"

# ============================================================================
# COLOR OUTPUT
# ============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# ============================================================================
# SEND TEST EMAIL
# ============================================================================

echo ""
log_info "📧 Sending test email..."
echo ""
echo "From:    $FROM"
echo "To:      $TO"
echo "Subject: $SUBJECT"
echo ""

# Send email
echo "$BODY" | mail -s "$SUBJECT" -r "$FROM" "$TO"

if [ $? -eq 0 ]; then
    log_info "✅ Test email sent successfully!"
    echo ""
    log_info "Check the recipient inbox: $TO"
    echo ""
    log_warn "If email doesn't arrive within 5 minutes:"
    echo "1. Check spam/junk folder"
    echo "2. Verify DNS records are configured"
    echo "3. Check mail logs:"
    echo "   sudo tail -f /var/log/mail.log"
    echo ""
    log_info "View mail queue:"
    echo "   mailq"
    echo ""
else
    log_warn "❌ Failed to send email"
    echo ""
    log_info "Check mail logs for errors:"
    echo "   sudo tail -100 /var/log/mail.log"
    echo ""
fi
