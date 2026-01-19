#!/bin/bash

# ============================================================================
# Email Testing Script
# ============================================================================
# This script provides various ways to test your SMTP server

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

DOMAIN="yourdomain.com"
FROM_EMAIL="admin@yourdomain.com"
TO_EMAIL="test@example.com"  # Change to your test email
HOSTNAME="mail.yourdomain.com"

# ============================================================================
# COLOR OUTPUT
# ============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

log_section() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# ============================================================================
# TEST 1: Send Email Using sendmail
# ============================================================================

test_sendmail() {
    log_section "TEST 1: Sending email using sendmail"
    
    echo "Subject: Test Email from sendmail
From: $FROM_EMAIL
To: $TO_EMAIL

This is a test email sent using sendmail command.
Sent at: $(date)
" | sendmail -v $TO_EMAIL

    log_info "Email sent via sendmail. Check the destination inbox."
}

# ============================================================================
# TEST 2: Send Email Using mail command
# ============================================================================

test_mail_command() {
    log_section "TEST 2: Sending email using mail command"
    
    echo "This is a test email sent using the mail command. Sent at: $(date)" | \
        mail -s "Test Email from mail command" $TO_EMAIL
    
    log_info "Email sent via mail command. Check the destination inbox."
}

# ============================================================================
# TEST 3: Test SMTP with telnet
# ============================================================================

test_telnet() {
    log_section "TEST 3: Testing SMTP with telnet"
    
    log_info "Connecting to localhost:25..."
    log_info "Commands to run manually:"
    echo ""
    echo "  EHLO $HOSTNAME"
    echo "  MAIL FROM:<$FROM_EMAIL>"
    echo "  RCPT TO:<$TO_EMAIL>"
    echo "  DATA"
    echo "  Subject: Test from telnet"
    echo "  "
    echo "  This is a test email."
    echo "  ."
    echo "  QUIT"
    echo ""
    log_info "Press Enter to start telnet session..."
    read
    
    telnet localhost 25
}

# ============================================================================
# TEST 4: Check Postfix Queue
# ============================================================================

test_queue() {
    log_section "TEST 4: Checking Postfix queue"
    
    mailq
    
    log_info "If the queue is empty, all emails have been sent."
    log_info "If there are emails in the queue, check /var/log/mail.log for errors"
}

# ============================================================================
# TEST 5: Check Mail Logs
# ============================================================================

test_logs() {
    log_section "TEST 5: Checking mail logs"
    
    log_info "Last 20 lines of /var/log/mail.log:"
    echo ""
    tail -n 20 /var/log/mail.log
    echo ""
    log_info "Look for 'status=sent' to confirm successful delivery"
}

# ============================================================================
# TEST 6: Test DKIM Signing
# ============================================================================

test_dkim() {
    log_section "TEST 6: Testing DKIM configuration"
    
    log_info "Testing DKIM key in DNS..."
    opendkim-testkey -d $DOMAIN -s default -vvv
    
    echo ""
    log_info "Send a test email to check-auth@verifier.port25.com"
    log_info "You'll receive a detailed report about SPF, DKIM, and DMARC"
}

# ============================================================================
# TEST 7: Test Authenticated SMTP (Port 587)
# ============================================================================

test_authenticated_smtp() {
    log_section "TEST 7: Testing authenticated SMTP (Port 587)"
    
    log_info "This test requires authentication credentials."
    log_info "You can use an email client or swaks tool:"
    echo ""
    echo "Install swaks:"
    echo "  sudo apt-get install swaks"
    echo ""
    echo "Send authenticated email:"
    echo "  swaks --to $TO_EMAIL \\"
    echo "        --from $FROM_EMAIL \\"
    echo "        --server $HOSTNAME \\"
    echo "        --port 587 \\"
    echo "        --auth-user $FROM_EMAIL \\"
    echo "        --auth-password YOUR_PASSWORD \\"
    echo "        --tls"
    echo ""
}

# ============================================================================
# TEST 8: Check DNS Records
# ============================================================================

test_dns() {
    log_section "TEST 8: Checking DNS records"
    
    log_info "Checking MX record..."
    dig MX $DOMAIN +short
    echo ""
    
    log_info "Checking SPF record..."
    dig TXT $DOMAIN +short | grep spf
    echo ""
    
    log_info "Checking DKIM record..."
    dig TXT default._domainkey.$DOMAIN +short
    echo ""
    
    log_info "Checking DMARC record..."
    dig TXT _dmarc.$DOMAIN +short
    echo ""
    
    log_info "Checking reverse DNS (PTR)..."
    SERVER_IP=$(curl -s ifconfig.me)
    dig -x $SERVER_IP +short
    echo ""
}

# ============================================================================
# TEST 9: Test TLS Connection
# ============================================================================

test_tls() {
    log_section "TEST 9: Testing TLS connection"
    
    log_info "Testing TLS on port 587..."
    echo "" | openssl s_client -connect $HOSTNAME:587 -starttls smtp
    
    echo ""
    log_info "Check the certificate chain and TLS version above"
}

# ============================================================================
# MAIN MENU
# ============================================================================

show_menu() {
    echo ""
    log_section "SMTP Server Testing Menu"
    echo ""
    echo "1. Send test email using sendmail"
    echo "2. Send test email using mail command"
    echo "3. Test SMTP manually with telnet"
    echo "4. Check Postfix queue"
    echo "5. Check mail logs"
    echo "6. Test DKIM configuration"
    echo "7. Test authenticated SMTP (Port 587)"
    echo "8. Check DNS records"
    echo "9. Test TLS connection"
    echo "10. Run all automated tests"
    echo "0. Exit"
    echo ""
    read -p "Select test (0-10): " choice
    
    case $choice in
        1) test_sendmail ;;
        2) test_mail_command ;;
        3) test_telnet ;;
        4) test_queue ;;
        5) test_logs ;;
        6) test_dkim ;;
        7) test_authenticated_smtp ;;
        8) test_dns ;;
        9) test_tls ;;
        10) 
            test_sendmail
            test_mail_command
            test_queue
            test_logs
            test_dkim
            test_dns
            ;;
        0) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_menu
}

# Start
show_menu
