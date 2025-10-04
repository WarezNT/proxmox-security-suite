# Quick Start Guide - Proxmox Security Suite

**Compatible with Proxmox VE 8.x and 9.x**

## 📝 Before You Begin

This guide will help you set up the Proxmox Security Suite on your infrastructure. Before starting, gather the following information:

### Required Information
- [ ] Your Proxmox server's **public IP address** (e.g., `203.0.113.10`)
- [ ] Your **domain name** (e.g., `yourdomain.com`)
- [ ] Your **Tailscale IP** (if already configured)
- [ ] Your **NPM container ID** (find it with `pct list`)
- [ ] Email address for security alerts
- [ ] Network subnet for private network (default: `10.10.0.0/24`)

### Finding Your Container IDs

```bash
# List all containers on your Proxmox server
pct list

# Example output:
# VMID       Status     Lock         Name
# 100        running                 webserver
# 200        running                 nginx-proxy-manager
# 300        stopped                 testcontainer

# In this example, NPM container ID is 200
```

## 🚀 Step-by-Step Installation

### Step 1: Download the Security Suite

```bash
# On your Proxmox server
cd /root
git clone https://github.com/WarezNT/proxmox-security-suite.git
cd proxmox-security-suite

# Or download directly
wget https://github.com/WarezNT/proxmox-security-suite/archive/main.zip
unzip main.zip
cd proxmox-security-suite-main
```

### Step 2: Make Script Executable

```bash
chmod +x setup.sh
```

### Step 3: Install the Complete Security Suite

```bash
sudo ./setup.sh
```

This will:
- ✅ Download all security scripts from `scripts/` folder
- ✅ Install Fail2Ban (brute-force protection)
- ✅ Install security monitoring tools
- ✅ Install automated update management
- ✅ Configure log monitoring and alerting
- ✅ Apply SSH hardening

> 📖 **Detailed Guides**: For in-depth explanations, see [EXTERNAL_RESOURCES.md](EXTERNAL_RESOURCES.md)

### Step 4: Configure Your Network Details

#### Edit Proxmox Firewall Rules

> 📖 **Official Guide**: [Proxmox Firewall](https://pve.proxmox.com/wiki/Firewall) - Complete firewall configuration reference

```bash
sudo nano /etc/pve/firewall/cluster.fw
```

Update the `[IPSET management]` section with your Tailscale IPs:

```
[IPSET management]
YOUR_TAILSCALE_IP_1 # Admin workstation
YOUR_TAILSCALE_IP_2 # Backup admin
```

**Learn More**: [Security Groups & IP Sets](https://pve.proxmox.com/wiki/Firewall#pve_firewall_security_groups)

#### Configure Network Interface (if needed)

> 📖 **Network Setup**: [Proxmox Network Configuration](https://pve.proxmox.com/wiki/Network_Configuration) - Bridges, VLANs, and advanced networking

```bash
sudo nano /etc/network/interfaces
```

Update the public IP and network settings:

```
auto vmbr0
iface vmbr0 inet static
    address YOUR_PUBLIC_IP/SUBNET
    gateway YOUR_GATEWAY
    bridge-ports eth0
    bridge-stp off
    bridge-fd 0
```

### Step 5: Configure Email Alerts

> 📖 **Email Setup**: [Proxmox Email Notifications](https://pve.proxmox.com/wiki/Email_Notification_Configuration) - SMTP configuration and testing

Edit the following files to set your email address:

```bash
# Fail2Ban alerts
sudo nano /etc/fail2ban/jail.local
# Change: destemail = your-email@domain.com

# Logwatch reports
sudo nano /etc/logwatch/conf/logwatch.conf
# Change: MailTo = your-email@domain.com

# Unattended upgrades
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
# Change: Unattended-Upgrade::Mail "your-email@domain.com";
```

### Step 6: Start Security Monitoring

```bash
# Start the security monitor
sudo systemctl start proxmox-security-monitor

# Enable it to start on boot
sudo systemctl enable proxmox-security-monitor

# Check status
proxmox-security status
```

### Step 7: Test Your Security Configuration

> 📖 **Security Testing**: [Testing Tools Guide](EXTERNAL_RESOURCES.md#testing--validation) - nmap, nikto, testssl.sh documentation

#### Internal Test (from Proxmox server)

```bash
proxmox-security test basic
```

#### External Test (from a different server/VPS)

⚠️ **CRITICAL REQUIREMENT**: Audit scripts **MUST** be run from:
- **Linux VPS** (recommended) or **Linux workstation**
- System **NOT connected** to your Tailscale network (Tailnet)
- Testing from a Tailscale-connected device will show **false positives**

**Why?** If your testing machine is on the same Tailnet, it will have access to management ports (22, 8006, 81), making them appear insecure when they're actually protected.

```bash
# Copy the test scripts to an external Linux server/VPS
scp scripts/audit/security-test.sh user@external-server:/tmp/
scp scripts/audit/advanced-security-test.sh user@external-server:/tmp/

# SSH to external server and run
ssh user@external-server
cd /tmp
chmod +x security-test.sh advanced-security-test.sh

# Basic test
./security-test.sh YOUR_PUBLIC_IP yourdomain.com YOUR_TAILSCALE_IP

# Advanced test (requires nmap, nikto)
./advanced-security-test.sh YOUR_PUBLIC_IP yourdomain.com
```

**Learn More**: [Nmap Documentation](https://nmap.org/book/man.html) | [Nikto Scanner](https://cirt.net/Nikto2)

#### Expected Test Results

✅ **Good Results:**
- Port 22 (SSH): `FILTERED` or `CLOSED`
- Port 8006 (Proxmox GUI): `FILTERED` or `CLOSED`
- Port 81 (NPM Admin): `FILTERED` or `CLOSED`
- Port 80 (HTTP): `OPEN`
- Port 443 (HTTPS): `OPEN`

❌ **Bad Results (Security Issues):**
- Management ports (22, 8006, 81) showing as `OPEN` from external tests

## 🔧 Common Configuration Tasks

### Add a New LXC Container to NPM

1. **Create the container with private IP:**
   ```bash
   pct create 101 local:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst \
     --hostname myservice \
     --net0 name=eth0,bridge=vmbr1,ip=10.10.0.10/24,gw=10.10.0.1 \
     --memory 2048 \
     --cores 2
   ```

2. **Add to Nginx Proxy Manager:**
   - Log in to NPM at `http://YOUR_TAILSCALE_IP:81`
   - Add Proxy Host:
     - Domain: `myservice.yourdomain.com`
     - Forward to: `10.10.0.10:80` (or your service port)
     - Enable SSL (Let's Encrypt)

3. **Update DNS:**
   - Add A record in Cloudflare: `myservice.yourdomain.com` → `YOUR_PUBLIC_IP`

### Configure Container Firewall

**Important:** Replace `101` with your actual container ID. For NPM container, use your NPM container ID.

```bash
# Enable firewall for container (replace 101 with your container ID)
pct set 101 -firewall 1

# Create firewall rules (replace 101 with your container ID)
nano /etc/pve/firewall/101.fw
```

Example rules:
```
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT

[RULES]
# Allow HTTP/HTTPS from private network
IN ACCEPT -source 10.10.0.0/24 -dport 80,443
# Allow SSH from Tailscale only
IN ACCEPT -source 100.64.0.0/10 -dport 22
# Drop everything else
IN DROP -log warning
```

**For NPM Container specifically:**
```bash
# Replace NPM_CONTAINER_ID with your actual NPM container ID
nano /etc/pve/firewall/NPM_CONTAINER_ID.fw
```

```
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT

[RULES]
# Allow HTTP/HTTPS from private network (for proxying)
IN ACCEPT -source 10.10.0.0/24 -dport 80,443
# Allow NPM admin panel from Tailscale only
IN ACCEPT -source 100.64.0.0/10 -dport 81
# Allow ICMP for monitoring
IN ACCEPT -p icmp
# Log and drop everything else
IN DROP -log warning
```

## 📊 Daily Operations

### Check Security Status

```bash
proxmox-security status
```

### View Security Logs

```bash
# Real-time monitoring
proxmox-security logs

# Or directly
tail -f /var/log/proxmox-security/security.log
```

### Generate Security Report

```bash
proxmox-security report
```

### Update System

```bash
# Check for updates
proxmox-security update check

# Apply security updates only
proxmox-security update security

# Update containers
proxmox-security update containers
```

## 🆘 Troubleshooting

### Can't Access Services from Internet

1. **Check Proxmox firewall:**
   ```bash
   pve-firewall status
   ```

2. **Verify iptables rules:**
   ```bash
   iptables -t nat -L PREROUTING -n -v
   ```

3. **Check NPM container status:**
   ```bash
   # Replace NPM_CONTAINER_ID with your container ID (e.g., 100, 200, 600)
   pct status NPM_CONTAINER_ID
   pct config NPM_CONTAINER_ID
   ```

4. **Test network connectivity:**
   ```bash
   ping 10.10.0.2
   curl -I http://10.10.0.2:80
   ```

### Can't Access Management via Tailscale

1. **Check Tailscale status:**
   ```bash
   tailscale status
   ip addr show tailscale0
   ```

2. **Restart Tailscale:**
   ```bash
   systemctl restart tailscaled
   ```

3. **Check firewall isn't blocking Tailscale:**
   ```bash
   iptables -L INPUT -n | grep tailscale
   ```

### Fail2Ban Not Working

1. **Check service status:**
   ```bash
   systemctl status fail2ban
   ```

2. **View banned IPs:**
   ```bash
   fail2ban-client status
   fail2ban-client status sshd
   ```

3. **Check logs:**
   ```bash
   tail -f /var/log/fail2ban.log
   ```

### Email Alerts Not Received

1. **Test mail configuration:**
   ```bash
   echo "Test" | mail -s "Test Email" your-email@domain.com
   ```

2. **Check Postfix status:**
   ```bash
   systemctl status postfix
   tail -f /var/log/mail.log
   ```

## 📚 Additional Resources

- Full documentation: See `README.md`
- Configuration examples: See `.github/copilot-instructions.md`
- Change history: See `CHANGELOG.md`

## 🔐 Security Best Practices

1. **Never expose management ports (22, 8006, 81) to the internet**
2. **Always use Tailscale VPN for management access**
3. **Keep Proxmox and containers updated regularly**
4. **Monitor security logs daily**
5. **Test security configuration monthly**
6. **Backup configurations before major changes**
7. **Use strong passwords and SSH keys**
8. **Enable 2FA where possible**

## ✅ Security Checklist

After installation, verify:

- [ ] Management ports closed from internet (test externally)
- [ ] Web services (80, 443) accessible publicly
- [ ] Tailscale VPN working for management
- [ ] Fail2Ban active and monitoring
- [ ] Email alerts configured and working
- [ ] Security monitoring service running
- [ ] Automatic updates enabled
- [ ] Firewall rules at container level
- [ ] Regular backups scheduled
- [ ] SSH hardened (key-only access)

## 🎯 Next Steps

1. Review the full `README.md` for detailed information
2. Customize firewall rules for your specific needs
3. Set up additional containers and services
4. Configure monitoring and alerting preferences
5. Schedule regular security audits
6. Document your specific configuration

---

**Need Help?** Check the troubleshooting section in `README.md` or review the comprehensive documentation in `.github/copilot-instructions.md`.