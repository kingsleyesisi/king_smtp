# DNS Configuration Reference for Cloudflare

This document provides a quick reference for all DNS records needed for your SMTP server.

## Required DNS Records

### 1. A Record (Mail Server)

```
Type: A
Name: mail
Content: YOUR_SERVER_IP
Proxy: DNS only (grey cloud)
TTL: Auto
```

**Example:**
```
Type: A
Name: mail
Content: 203.0.113.10
```

### 2. MX Record

```
Type: MX
Name: @
Content: mail.yourdomain.com
Priority: 10
TTL: Auto
```

### 3. SPF Record

```
Type: TXT
Name: @
Content: v=spf1 mx a:mail.yourdomain.com ~all
TTL: Auto
```

**Advanced SPF (if using additional mail services):**
```
v=spf1 mx a:mail.yourdomain.com include:_spf.google.com ~all
```

### 4. DKIM Record

**Get your DKIM key:**
```bash
sudo cat /etc/opendkim/keys/yourdomain.com/default.txt
```

**DNS Record:**
```
Type: TXT
Name: default._domainkey
Content: v=DKIM1; k=rsa; p=YOUR_PUBLIC_KEY_HERE
TTL: Auto
```

**Important:** Remove all quotes, parentheses, and newlines. Combine into single line.

**Example:**
```
v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1234567890abcdef...
```

### 5. DMARC Record

```
Type: TXT
Name: _dmarc
Content: v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com
TTL: Auto
```

**DMARC Policy Options:**
- `p=none` - Monitor only (recommended for testing)
- `p=quarantine` - Move suspicious emails to spam
- `p=reject` - Reject suspicious emails (strictest)

**Advanced DMARC:**
```
v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com; ruf=mailto:forensic@yourdomain.com; pct=100; adkim=s; aspf=s
```

Where:
- `rua` - Aggregate reports email
- `ruf` - Forensic reports email
- `pct` - Percentage of emails to apply policy (100 = all)
- `adkim` - DKIM alignment mode (r=relaxed, s=strict)
- `aspf` - SPF alignment mode (r=relaxed, s=strict)

## Verification Commands

### Check All DNS Records

```bash
# MX Record
dig MX yourdomain.com +short

# SPF Record
dig TXT yourdomain.com +short | grep spf

# DKIM Record
dig TXT default._domainkey.yourdomain.com +short

# DMARC Record
dig TXT _dmarc.yourdomain.com +short

# A Record
dig A mail.yourdomain.com +short

# Reverse DNS (PTR)
dig -x YOUR_SERVER_IP +short
```

## Reverse DNS (PTR Record)

**This MUST be configured in AWS EC2, not Cloudflare**

1. Go to AWS EC2 Console
2. Navigate to: Network & Security → Elastic IPs
3. Select your IP address
4. Actions → Update reverse DNS
5. Enter: `mail.yourdomain.com`
6. Submit request

**Verify:**
```bash
dig -x YOUR_SERVER_IP +short
# Should return: mail.yourdomain.com.
```

## Common DNS Issues

### 1. DKIM Record Too Long

If your DKIM public key is very long, you may need to split it:

```
v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA... (first part) ...
```

Some DNS providers have character limits. If so:
- Use a shorter selector name
- Regenerate with 1024-bit key (less secure)
- Contact Cloudflare support

### 2. DNS Propagation Time

After adding/changing records:
- Cloudflare: Usually instant to 5 minutes
- Global propagation: Up to 48 hours

Check propagation:
```bash
dig @8.8.8.8 TXT default._domainkey.yourdomain.com
dig @1.1.1.1 TXT default._domainkey.yourdomain.com
```

### 3. Cloudflare Proxy Issues

**Important:** The A record for `mail.yourdomain.com` must be **DNS only** (grey cloud), not proxied (orange cloud).

If proxied:
- SMTP connections will fail
- SSL certificates won't work
- Email cannot be sent/received

## Testing DNS Configuration

### Online Tools

1. **MXToolbox**
   - Visit: https://mxtoolbox.com/SuperTool.aspx
   - Test: MX, SPF, DKIM, DMARC records

2. **DKIM Validator**
   - Visit: https://dkimvalidator.com/
   - Get a test email address
   - Send an email to it
   - View DKIM signature validation

3. **Mail Tester**
   - Visit: https://www.mail-tester.com/
   - Send email to provided address
   - Get a score out of 10

4. **Port25 Verifier**
   - Send email to: check-auth@verifier.port25.com
   - Receive detailed SPF/DKIM/DMARC report

## Complete Example

For domain: `example.com`
Server IP: `203.0.113.10`

```
# A Record
mail.example.com. IN A 203.0.113.10

# MX Record
example.com. IN MX 10 mail.example.com.

# SPF Record
example.com. IN TXT "v=spf1 mx a:mail.example.com ~all"

# DKIM Record
default._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=MIIBIjAN..."

# DMARC Record
_dmarc.example.com. IN TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"

# PTR Record (in AWS)
10.113.0.203.in-addr.arpa. IN PTR mail.example.com.
```

## Troubleshooting

### Record Not Found

```bash
# Check if record exists
dig TXT default._domainkey.yourdomain.com

# If no answer, verify:
# 1. Record name is correct
# 2. Record type is correct (TXT)
# 3. DNS has propagated (wait 5-10 minutes)
```

### SPF Fails

**Common issues:**
- Missing `v=spf1` at the beginning
- Wrong mechanism order
- Too many DNS lookups (max 10)

**Test SPF:**
```bash
dig TXT yourdomain.com +short | grep spf
```

### DKIM Fails

**Common issues:**
- Extra quotes or parentheses in DNS record
- Newlines in DNS record
- Wrong selector name
- DNS not propagated

**Test DKIM:**
```bash
sudo opendkim-testkey -d yourdomain.com -s default -vvv
```

Expected: `opendkim-testkey: key OK`

## Next Steps

After configuring all DNS records:

1. Wait 10-15 minutes for propagation
2. Verify all records with dig commands
3. Test DKIM: `sudo opendkim-testkey -d yourdomain.com -s default -vvv`
4. Send test email to check-auth@verifier.port25.com
5. Send test email to mail-tester.com
6. Monitor first few emails for delivery issues
