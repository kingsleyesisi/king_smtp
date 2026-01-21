# Kings SMTP Relay

A simple, send-only SMTP relay setup.

## Quick Start

1. **Setup**
   ```bash
   sudo bash setup.sh
   ```
   This will install Postfix, configure it for send-only (SASL auth enabled, no IMAP/POP3), and detect your public IP.

2. **DNS Configuration**
   After setup, view the DNS records you need to add to Cloudflare:
   ```bash
   sudo bash scripts/show-config.sh
   ```

3. **Verify**
   Once you've added the DNS records, verify propagation:
   ```bash
   sudo bash scripts/verify-dns.sh
   ```

4. **Test**
   Send a test email:
   ```bash
   sudo bash scripts/test-email.sh
   ```

## Configuration

The configuration is stored in `.env`. The setup script creates this from defaults if it doesn't exist.
