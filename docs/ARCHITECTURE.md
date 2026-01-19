# Kings SMTP Architecture Diagrams

## AWS Infrastructure Overview

```mermaid
graph TB
    subgraph "Internet"
        User[Email Client]
        Sender[External Mail Server]
        DNS[DNS Provider]
    end
    
    subgraph "AWS Cloud"
        subgraph "VPC"
            subgraph "Public Subnet"
                EC2[EC2 Instance<br/>Ubuntu 22.04<br/>t2.small]
                SG[Security Group]      
            end
        end
        EIP[Elastic IP<br/>Static Public IP]
        R53[Route 53<br/>DNS Records]
    end
    
    User -->|SMTP: 587| EIP
    Sender -->|SMTP: 25| EIP
    User -->|IMAP: 993| EIP
    EIP --> SG
    SG --> EC2
    DNS -.->|DNS Queries| R53
    R53 -.->|Returns IP| DNS
    
    style EC2 fill:#FF9900
    style EIP fill:#FF9900
    style R53 fill:#FF9900
    style SG fill:#3F8624
```

## Mail Server Components

```mermaid
graph LR
    subgraph "EC2 Instance: mail.yourdomain.com"
        subgraph "Incoming Email"
            SMTP25[Postfix<br/>Port 25<br/>SMTP]
        end
        
        subgraph "Outgoing Email"
            SMTP587[Postfix<br/>Port 587<br/>Submission]
        end
        
        subgraph "Email Delivery"
            Dovecot[Dovecot<br/>Port 993<br/>IMAP/POP3]
        end
        
        subgraph "Authentication"
            DKIM[OpenDKIM<br/>Email Signing]
            SASL[SASL<br/>Auth]
        end
        
        subgraph "Storage"
            MailDir[/var/mail/vmail]
        end
        
        subgraph "Security"
            SSL[Let's Encrypt<br/>SSL/TLS Certs]
            UFW[UFW Firewall]
        end
    end
    
    SMTP25 --> DKIM
    SMTP587 --> SASL
    SASL --> DKIM
    DKIM --> MailDir
    Dovecot --> MailDir
    SSL --> SMTP25
    SSL --> SMTP587
    SSL --> Dovecot
    
    style SMTP25 fill:#4CAF50
    style SMTP587 fill:#2196F3
    style Dovecot fill:#FF9800
    style DKIM fill:#9C27B0
    style SSL fill:#F44336
```

## Email Flow Diagram

### Sending Email (Outbound)

```mermaid
sequenceDiagram
    participant Client as Email Client
    participant Postfix as Postfix (587)
    participant DKIM as OpenDKIM
    participant Remote as Recipient Server
    
    Client->>Postfix: EHLO + STARTTLS
    Postfix->>Client: 220 Ready for TLS
    Client->>Postfix: AUTH LOGIN
    Postfix->>Client: 235 Authentication successful
    Client->>Postfix: MAIL FROM + RCPT TO + DATA
    Postfix->>DKIM: Sign email
    DKIM->>DKIM: Add DKIM signature
    DKIM->>Postfix: Return signed email
    Postfix->>Remote: Deliver via SMTP (25)
    Remote->>Remote: Verify SPF, DKIM, DMARC
    Remote->>Postfix: 250 OK
    Postfix->>Client: 250 Message accepted
```

### Receiving Email (Inbound)

```mermaid
sequenceDiagram
    participant Sender as Sender Server
    participant Postfix as Postfix (25)
    participant Dovecot as Dovecot
    participant Storage as Mail Storage
    participant Client as Email Client
    
    Sender->>Postfix: SMTP Connection (25)
    Postfix->>Postfix: Check SPF, DNS
    Sender->>Postfix: MAIL FROM + RCPT TO
    Postfix->>Postfix: Validate recipient
    Sender->>Postfix: Email DATA
    Postfix->>Dovecot: Deliver via LMTP
    Dovecot->>Storage: Store in /var/mail/vmail
    Storage->>Dovecot: Stored successfully
    Dovecot->>Postfix: 250 OK
    Postfix->>Sender: 250 Message accepted
    
    Note over Client,Storage: Later...
    Client->>Dovecot: IMAP Login (993)
    Dovecot->>Storage: Fetch emails
    Storage->>Dovecot: Return messages
    Dovecot->>Client: Display emails
```

## DNS Configuration Flow

```mermaid
graph TB
    subgraph "DNS Records Required"
        A[A Record<br/>mail.yourdomain.com → IP]
        MX[MX Record<br/>yourdomain.com → mail.yourdomain.com]
        SPF[SPF Record<br/>TXT: v=spf1 mx ip4:IP ~all]
        DKIM[DKIM Record<br/>TXT: default._domainkey]
        DMARC[DMARC Record<br/>TXT: _dmarc]
        PTR[PTR Record<br/>IP → mail.yourdomain.com]
    end
    
    subgraph "Validation Services"
        Sender[Sending Server]
        Receiver[Receiving Server]
    end
    
    A --> Sender
    Sender --> MX
    Sender --> SPF
    Sender --> DKIM
    Receiver --> DMARC
    Receiver --> PTR
    
    style A fill:#4CAF50
    style MX fill:#2196F3
    style SPF fill:#FF9800
    style DKIM fill:#9C27B0
    style DMARC fill:#F44336
    style PTR fill:#00BCD4
```

## Security & Authentication Flow

```mermaid
graph LR
    subgraph "Client Authentication"
        C1[Email Client]
        C1 -->|1. Connect| TLS[TLS/SSL<br/>Encryption]
        TLS -->|2. Encrypted| AUTH[SASL Auth]
        AUTH -->|3. Username/Password| DB[User Database]
        DB -->|4. Validated| SEND[Send Email]
    end
    
    subgraph "Email Signing"
        SEND -->|5. Add Headers| SIGN[DKIM Signing]
        SIGN -->|6. Private Key| KEY[/etc/opendkim/keys]
        KEY -->|7. Signed| OUT[Outbound Email]
    end
    
    subgraph "Recipient Verification"
        OUT -->|8. Send| REC[Recipient Server]
        REC -->|9. Verify DKIM| DNS1[DNS: DKIM Public Key]
        REC -->|10. Verify SPF| DNS2[DNS: SPF Record]
        REC -->|11. Check DMARC| DNS3[DNS: DMARC Policy]
        DNS1 --> DECISION
        DNS2 --> DECISION
        DNS3 --> DECISION[Accept/Reject<br/>Decision]
        DECISION -->|Pass| INBOX[Inbox]
        DECISION -->|Fail| SPAM[Spam/Reject]
    end
    
    style TLS fill:#F44336
    style SIGN fill:#9C27B0
    style INBOX fill:#4CAF50
    style SPAM fill:#FF5722
```

## AWS Deployment Workflow

```mermaid
graph TD
    START[Start Deployment] --> EC2[Launch EC2 Instance]
    EC2 --> EIP[Allocate Elastic IP]
    EIP --> SG[Configure Security Group]
    SG --> PORT25[Request Port 25 Unblock]
    
    PORT25 --> DNS[Configure DNS Records]
    DNS --> PTR[Set Reverse DNS/PTR]
    PTR --> SSH[SSH into Instance]
    
    SSH --> UPDATE[Update System]
    UPDATE --> CLONE[Clone Repository]
    CLONE --> CONFIG[Edit Configuration]
    CONFIG --> INSTALL[Run install.sh]
    
    INSTALL --> WAIT{Installation<br/>Success?}
    WAIT -->|Yes| DKIM_DNS[Add DKIM to DNS]
    WAIT -->|No SSL| MANUAL_SSL[Fix SSL Issue]
    MANUAL_SSL --> RETRY[Retry Certbot]
    RETRY --> DKIM_DNS
    
    DKIM_DNS --> VERIFY[Verify Services]
    VERIFY --> TEST[Send Test Email]
    TEST --> MAIL_TEST{Mail Tester<br/>Score ≥ 9?}
    
    MAIL_TEST -->|Yes| PROD[Production Ready ✓]
    MAIL_TEST -->|No| DEBUG[Debug DNS/Config]
    DEBUG --> TEST
    
    PROD --> MONITOR[Setup Monitoring]
    MONITOR --> BACKUP[Configure Backups]
    BACKUP --> DONE[Deployment Complete!]
    
    style START fill:#4CAF50
    style DONE fill:#4CAF50
    style PROD fill:#2196F3
    style MANUAL_SSL fill:#FF9800
    style DEBUG fill:#FF5722
```

## Port and Protocol Reference

```mermaid
graph LR
    subgraph "Postfix (Mail Server)"
        P25[Port 25<br/>SMTP<br/>Incoming Mail]
        P587[Port 587<br/>Submission<br/>Outgoing Mail<br/>STARTTLS]
    end
    
    subgraph "Dovecot (Mail Delivery)"
        P993[Port 993<br/>IMAPS<br/>Secure IMAP<br/>SSL/TLS]
        P995[Port 995<br/>POP3S<br/>Secure POP3<br/>SSL/TLS]
    end
    
    subgraph "Web/Management"
        P80[Port 80<br/>HTTP<br/>Let's Encrypt]
        P443[Port 443<br/>HTTPS<br/>Web Mail<br/>Optional]
    end
    
    subgraph "Admin"
        P22[Port 22<br/>SSH<br/>Server Access]
    end
    
    style P25 fill:#4CAF50
    style P587 fill:#2196F3
    style P993 fill:#FF9800
    style P80 fill:#F44336
    style P22 fill:#9C27B0
```

## File System Structure

```
/
├── etc/
│   ├── postfix/
│   │   ├── main.cf              # Main Postfix config
│   │   ├── master.cf            # Service definitions
│   │   └── virtual              # Virtual aliases
│   ├── dovecot/
│   │   ├── dovecot.conf         # Main Dovecot config
│   │   ├── conf.d/
│   │   │   ├── 10-auth.conf    # Authentication
│   │   │   ├── 10-master.conf  # Services
│   │   │   └── 10-ssl.conf     # SSL/TLS
│   │   └── users                # Email user database
│   ├── opendkim/
│   │   ├── opendkim.conf        # DKIM config
│   │   ├── TrustedHosts         # Trusted relay hosts
│   │   └── keys/
│   │       └── yourdomain.com/
│   │           ├── default.private  # Private key (keep secret!)
│   │           └── default.txt      # Public key (add to DNS)
│   └── letsencrypt/
│       └── live/
│           └── mail.yourdomain.com/
│               ├── fullchain.pem    # SSL certificate
│               └── privkey.pem      # Private key
└── var/
    ├── mail/
    │   └── vmail/
    │       └── yourdomain.com/
    │           └── admin/           # Email storage
    │               ├── cur/
    │               ├── new/
    │               └── tmp/
    └── log/
        ├── mail.log                 # Main mail log
        └── letsencrypt/
            └── letsencrypt.log      # SSL cert logs
```

## Cost Breakdown (AWS)

```mermaid
pie title Monthly AWS Costs (USD)
    "EC2 Instance (t2.small)" : 17
    "EBS Storage (20GB)" : 2
    "Data Transfer" : 1
    "Elastic IP (in use)" : 0
```

**Total: ~$20/month**

## Email Deliverability Score Components

```mermaid
graph TB
    subgraph "Mail Tester Score (10/10)"
        DKIM[DKIM Signature<br/>+2 points]
        SPF[SPF Valid<br/>+2 points]
        DMARC[DMARC Policy<br/>+1 point]
        PTR[Reverse DNS<br/>+1 point]
        SSL[TLS/SSL<br/>+1 point]
        CONTENT[Content Quality<br/>+2 points]
        BLACKLIST[Not Blacklisted<br/>+1 point]
    end
    
    DKIM --> SCORE
    SPF --> SCORE
    DMARC --> SCORE
    PTR --> SCORE
    SSL --> SCORE
    CONTENT --> SCORE
    BLACKLIST --> SCORE[Total Score]
    
    SCORE --> RESULT{Score?}
    RESULT -->|10/10| INBOX[Inbox Delivery]
    RESULT -->|7-9/10| MIXED[Mixed Results]
    RESULT -->|<7/10| SPAM[Likely Spam]
    
    style INBOX fill:#4CAF50
    style MIXED fill:#FF9800
    style SPAM fill:#F44336
```

---

## Legend

- **Orange boxes**: AWS services
- **Green boxes**: Mail receiving
- **Blue boxes**: Mail sending
- **Purple boxes**: Security/Authentication
- **Red boxes**: SSL/TLS encryption

## Useful Links

- [AWS EC2 Pricing](https://aws.amazon.com/ec2/pricing/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [Postfix Documentation](http://www.postfix.org/)
- [OpenDKIM Configuration](http://opendkim.org/)
- [RFC 5321 - SMTP](https://tools.ietf.org/html/rfc5321)
