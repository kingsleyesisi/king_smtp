#!/bin/bash

# ============================================================================
# SMTP Server Easy Setup Script
# ============================================================================
# This script is a simple wrapper to install and configure the SMTP server.
# It ensures everything is run with the right permissions and order.

set -e

# ============================================================================
# PRE-CHECKS
# ============================================================================

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo:"
    echo "sudo bash setup.sh"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ============================================================================
# RUN INSTALLATION
# ============================================================================

echo "Starting SMTP Server Installation..."
echo "This will configure Postfix, OpenDKIM, and SSL."
echo ""

bash "$SCRIPT_DIR/scripts/install.sh"

# ============================================================================
# RUN VERIFICATION
# ============================================================================

echo ""
echo "Running initial verification..."
bash "$SCRIPT_DIR/scripts/verify-dns.sh"

echo ""
echo "=============================================================================="
echo "Setup Complete!"
echo "=============================================================================="
echo "You can check your configuration anytime with:"
echo "sudo bash scripts/show-config.sh"
echo ""
