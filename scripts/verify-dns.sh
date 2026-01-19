#!/bin/bash

# ============================================================================
# DNS Verification Script - Kings SMTP
# ============================================================================
# This script checks if all required DNS records are properly configured
# Usage: sudo bash scripts/verify-dns.sh

set -e

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env file
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
else
    echo "ERROR: .env file not found"
    exit 1
fi

# Use hardcoded IP if available, otherwise auto-detect
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || hostname -I | awk '{print $1}')
fi

# ============================================================================
# COLOR OUTPUT
# ============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_pass() {
    echo -e "${GREEN}✅ PASS${NC} $1"
}

log_fail() {
    echo -e "${RED}❌ FAIL${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠️  WARN${NC} $1"
}

log_info() {
    echo -e "${CYAN}ℹ️  INFO${NC} $1"
}

# ============================================================================
# DNS VERIFICATION TESTS
# ============================================================================

echo ""
echo "=============================================================================="
echo "  DNS VERIFICATION FOR $DOMAIN"
echo "=============================================================================="
echo ""
log_info "Server IP: $SERVER_IP"
log_info "Hostname: $HOSTNAME"
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: A Record
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1: A Record for $HOSTNAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
A_RESULT=$(dig $HOSTNAME +short | head -n1)
if [ "$A_RESULT" = "$SERVER_IP" ]; then
    log_pass "A record is correct: $HOSTNAME → $SERVER_IP"
    ((TESTS_PASSED++))
else
    log_fail "A record incorrect or not found"
    log_info "Expected: $SERVER_IP"
    log_info "Got: $A_RESULT"
    ((TESTS_FAILED++))
fi
echo ""

# Test 2: MX Record
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2: MX Record for $DOMAIN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
MX_RESULT=$(dig $DOMAIN MX +short)
if echo "$MX_RESULT" | grep -q "$HOSTNAME"; then
    log_pass "MX record is correct"
    log_info "Result: $MX_RESULT"
    ((TESTS_PASSED++))
else
    log_fail "MX record not found or incorrect"
    log_info "Expected to contain: $HOSTNAME"
    log_info "Got: $MX_RESULT"
    ((TESTS_FAILED++))
fi
echo ""

# Test 3: SPF Record
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 3: SPF Record for $DOMAIN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SPF_RESULT=$(dig $DOMAIN TXT +short | grep -i "spf")
if echo "$SPF_RESULT" | grep -q "v=spf1"; then
    log_pass "SPF record found"
    log_info "Result: $SPF_RESULT"
    ((TESTS_PASSED++))
else
    log_fail "SPF record not found"
    log_info "Expected: v=spf1 mx ip4:$SERVER_IP ~all"
    ((TESTS_FAILED++))
fi
echo ""

# Test 4: DKIM Record
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 4: DKIM Record for $DOMAIN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
DKIM_RESULT=$(dig default._domainkey.$DOMAIN TXT +short)
if echo "$DKIM_RESULT" | grep -q "v=DKIM1"; then
    log_pass "DKIM record found"
    log_info "DKIM key is configured"
    ((TESTS_PASSED++))
else
    log_fail "DKIM record not found"
    log_info "Run: sudo cat /etc/opendkim/keys/$DOMAIN/default.txt"
    log_info "Add the DKIM record to your DNS"
    ((TESTS_FAILED++))
fi
echo ""

# Test 5: DMARC Record
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 5: DMARC Record for $DOMAIN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
DMARC_RESULT=$(dig _dmarc.$DOMAIN TXT +short)
if echo "$DMARC_RESULT" | grep -q "v=DMARC1"; then
    log_pass "DMARC record found"
    log_info "Result: $DMARC_RESULT"
    ((TESTS_PASSED++))
else
    log_fail "DMARC record not found"
    log_info "Expected: v=DMARC1; p=quarantine; rua=mailto:$ADMIN_EMAIL"
    ((TESTS_FAILED++))
fi
echo ""

# Test 6: PTR Record (Reverse DNS)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 6: PTR Record (Reverse DNS) for $SERVER_IP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
PTR_RESULT=$(dig -x $SERVER_IP +short)
if echo "$PTR_RESULT" | grep -q "$HOSTNAME"; then
    log_pass "PTR (Reverse DNS) is correct: $SERVER_IP → $PTR_RESULT"
    ((TESTS_PASSED++))
else
    log_fail "PTR record not configured"
    log_info "Go to AWS EC2 Console → Elastic IPs"
    log_info "Select $SERVER_IP → Actions → Update reverse DNS"
    log_info "Enter: $HOSTNAME"
    ((TESTS_FAILED++))
fi
echo ""

# Test 7: DKIM Validation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 7: DKIM Key Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v opendkim-testkey &> /dev/null; then
    DKIM_TEST=$(opendkim-testkey -d $DOMAIN -s default -vvv 2>&1)
    if echo "$DKIM_TEST" | grep -q "key OK"; then
        log_pass "DKIM key validation passed"
        ((TESTS_PASSED++))
    else
        log_warn "DKIM key validation warning (may need more time for DNS propagation)"
        log_info "Run: sudo opendkim-testkey -d $DOMAIN -s default -vvv"
    fi
else
    log_info "OpenDKIM not installed, skipping DKIM validation"
fi
echo ""

# Summary
echo "=============================================================================="
echo "  VERIFICATION SUMMARY"
echo "=============================================================================="
echo ""
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    log_pass "All DNS records are properly configured!"
    echo ""
    log_info "Your mail server is ready to send emails."
    log_info "Test with: sudo bash scripts/test-email.sh"
    echo ""
elif [ $TESTS_FAILED -le 2 ]; then
    log_warn "Some DNS records need attention"
    echo ""
    log_info "Fix the failed tests above and wait 5-60 minutes for DNS propagation"
    log_info "Then run this script again: sudo bash scripts/verify-dns.sh"
    echo ""
else
    log_fail "Multiple DNS records are missing"
    echo ""
    log_info "Please add the DNS records from: DNS_RECORDS.txt"
    log_info "Wait 5-60 minutes for propagation, then run this script again"
    echo ""
fi

echo "=============================================================================="
echo ""
