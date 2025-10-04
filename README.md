# Proxmox Security Suite

**The first and only complete automated security suite for Proxmox VE** - From zero to secured in 15 minutes, no security expertise required.

[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Proxmox](https://img.shields.io/badge/Proxmox-8.x%20%7C%209.x-orange)](https://www.proxmox.com/)
[![Automation](https://img.shields.io/badge/automation-100%25-blue)](README.md)
[![Release](https://img.shields.io/github/v/release/WarezNT/proxmox-security-suite)](https://github.com/WarezNT/proxmox-security-suite/releases)
[![Downloads](https://img.shields.io/github/downloads/WarezNT/proxmox-security-suite/total)](https://github.com/WarezNT/proxmox-security-suite/releases)

---

## ⚠️ DISCLAIMER

**USE AT YOUR OWN RISK**

This software is provided "as is", without warranty of any kind, express or implied. The authors and contributors:

- Make **NO WARRANTIES** regarding the security, reliability, or functionality of these scripts
- Are **NOT LIABLE** for any damages, data loss, system failures, or security breaches that may occur
- **DO NOT guarantee** that these scripts will prevent all security threats or attacks
- **STRONGLY RECOMMEND** testing in a non-production environment first
- **ADVISE** maintaining proper backups before making any system changes

**By using this software, you acknowledge that:**
- You understand the risks involved in modifying system security configurations
- You have adequate technical knowledge or will seek professional assistance
- You accept full responsibility for any consequences of using these scripts
- The authors cannot be held liable for any direct or indirect damages

**Security Note:** This suite implements industry-standard security practices, but no security solution is 100% foolproof. Always maintain multiple layers of security, keep systems updated, and monitor regularly.

---

## 🌟 Why This Project?

Unlike manual hardening guides or partial security scripts, this is the **only complete security automation suite** for Proxmox:

| Feature | Proxmox Security Suite | Alternatives |
|---------|------------------------|--------------|
| **Complete Automation** | ✅ One-command install | ❌ Manual or minimal |
| **Real-time Monitoring** | ✅ systemd service + alerts | ❌ None |
| **Fail2Ban Integration** | ✅ Auto-setup + Proxmox filters | ❌ Not included |
| **Container Firewall** | ✅ Automated per-LXC rules | ❌ Manual only |
| **Automated Updates** | ✅ Security management | ❌ Not included |
| **Security Testing** | ✅ Basic + Advanced tests | ❌ Audit only |
| **Tailscale Integration** | ✅ Built-in VPN model | ❌ Not covered |
| **NPM Integration** | ✅ Reverse proxy security | ❌ Not covered |
| **Unified Management** | ✅ `proxmox-security` command | ❌ Multiple manual steps |

**Positioning:** Turnkey security suite that hardens, monitors, updates, and tests your Proxmox infrastructure with a single command.

---

## 📋 Table of Contents

- [Disclaimer](#️-disclaimer)
- [Overview](#-overview)
- [Security Architecture](#️-security-architecture)
- [Quick Installation](#-quick-installation)
- [Included Scripts](#-included-scripts)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Security Testing](#-security-testing)
- [Monitoring & Alerting](#-monitoring--alerting)
- [Troubleshooting](#-troubleshooting)
- [Best Practices](#-best-practices)
- [External Resources](#-external-resources)

**📄 [Full Disclaimer Document](DISCLAIMER.md)**

## 🎯 Overview

Complete security solution for Proxmox VE infrastructure including:

- **Proxmox VE**: Main virtualization platform
- **Nginx Proxy Manager (NPM)**: Reverse proxy for public services
- **Tailscale VPN**: Secure management access
- **Cloudflare**: DNS and SSL/TLS management

### 🏗️ Security Architecture

```
Internet → Cloudflare → Proxmox (YOUR_PUBLIC_IP) → NPM (10.10.0.2) → Services
                                ↓
                          Tailscale VPN (YOUR_TAILSCALE_IP) → Management Access
```

**Security Principles:**
- ✅ Separate public traffic from management
- ✅ Management access only via Tailscale VPN
- ✅ Multi-layer firewall (Proxmox + Container + iptables)
- ✅ Real-time monitoring and alerting
- ✅ Automated security updates
- ✅ Automated configuration backups

## 🚀 Quick Installation

**Compatible with Proxmox VE 8.x and 9.x**

### On Proxmox Host

```bash
# Download and run installer
wget https://raw.githubusercontent.com/WarezNT/proxmox-security-suite/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

The installer will:
- Install Fail2Ban, monitoring tools, and dependencies
- Download core security scripts (hardening, monitoring, updates)
- Configure multi-layer firewalls
- Set up automated security updates
- Create system command wrappers
- Configure real-time monitoring service

**Post-Installation:** Configure email addresses in:
- `/etc/fail2ban/jail.local`
- `/etc/logwatch/conf/logwatch.conf`
- `/etc/apt/apt.conf.d/50unattended-upgrades`

### On External VPS (for security testing)

```bash
# Download audit scripts to external VPS (NOT Proxmox)
wget https://raw.githubusercontent.com/WarezNT/proxmox-security-suite/main/scripts/audit/security-test.sh
wget https://raw.githubusercontent.com/WarezNT/proxmox-security-suite/main/scripts/audit/advanced-security-test.sh
chmod +x *.sh

# Run security tests from external VPS
./security-test.sh YOUR_PROXMOX_PUBLIC_IP yourdomain.com
./advanced-security-test.sh YOUR_PROXMOX_PUBLIC_IP yourdomain.com
```

⚠️ **CRITICAL:** Audit scripts must run from a VPS that is NOT connected to the same Tailscale network as your Proxmox server. Testing from inside the Tailnet will show false positives.

## 📦 Included Scripts

### Main Installer

#### `setup.sh`
One-command installation of entire security suite.

```bash
sudo ./setup.sh
```

### Core Scripts (`scripts/core/`)

#### `security-hardening.sh`
Interactive system hardening wizard with Fail2Ban, SSH hardening, and firewall configuration.

```bash
sudo proxmox-security-hardening
```

#### `security-monitor.sh`
Real-time security monitoring daemon with email/syslog alerting.

```bash
sudo systemctl start proxmox-security-monitor
sudo systemctl status proxmox-security-monitor
```

#### `security-updates.sh`
Automated security update management with backup/rollback capability.

```bash
sudo proxmox-security-updates check      # Check updates
sudo proxmox-security-updates security   # Apply security updates
sudo proxmox-security-updates backup     # Backup configs
```

### Audit Scripts (`scripts/audit/`)

⚠️ **IMPORTANT:** These scripts must be downloaded and run from an external VPS that is NOT connected to your Tailscale network.

#### `security-test.sh`
Basic security testing (ports, SSL/TLS, firewall rules).

**Run from external VPS:**
```bash
./security-test.sh YOUR_PROXMOX_PUBLIC_IP yourdomain.com YOUR_TAILSCALE_IP
```

#### `advanced-security-test.sh`
Advanced penetration testing with nmap, nikto, and comprehensive vulnerability scanning.

**Run from external VPS:**
```bash
./advanced-security-test.sh YOUR_PROXMOX_PUBLIC_IP yourdomain.com
```

**Expected Results:**
- ✅ Management ports (22, 8006, 81): `FILTERED` or `CLOSED`
- ✅ Public ports (80, 443): `OPEN`

If management ports show as `OPEN`, this indicates a critical security issue.

## ⚙️ Configuration

### Proxmox Firewall

```bash
# /etc/pve/firewall/cluster.fw
[IPSET management]
192.168.1.100 # Trusted admin IP

[RULES]
IN ACCEPT -source 0.0.0.0/0 -dport 80,443 -proto tcp
IN ACCEPT -source +management -dport 22,8006 -proto tcp
IN DROP -dport 22,8006 -proto tcp -log warning
```

### NPM Container Firewall

```bash
# /etc/pve/firewall/NPM_CONTAINER_ID.fw
[OPTIONS]
enable: 1
policy_in: DROP

[RULES]
IN ACCEPT -source 10.10.0.0/24 -dport 80,443
IN ACCEPT -source 100.64.0.0/10 -dport 81  # Tailscale only
IN DROP -log warning
```

### Network Configuration

```bash
# /etc/network/interfaces
auto vmbr1
iface vmbr1 inet static
    address 10.10.0.1/24
    bridge_ports none
    post-up echo 1 > /proc/sys/net/ipv4/ip_forward
    post-up iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o eth0 -j MASQUERADE
    post-up iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 10.10.0.2:80
    post-up iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j DNAT --to-destination 10.10.0.2:443
    post-up iptables -t nat -A PREROUTING -i tailscale0 -p tcp --dport 81 -j DNAT --to-destination 10.10.0.2:81
```

## 🎮 Usage

### Daily Management

```bash
proxmox-security-monitor status                    # Check security status
sudo journalctl -u proxmox-security-monitor -f     # View logs
proxmox-security-monitor report                    # Generate report
```

### Update Management

```bash
proxmox-security-updates check      # Check for updates
proxmox-security-updates security   # Apply security updates
proxmox-security-updates backup     # Manual backup
proxmox-security-updates rollback   # Restore previous config
```

## 🧪 Security Testing

⚠️ **CRITICAL**: Audit scripts must be run from an **external system** (Linux VPS or workstation) that is **NOT connected to your Tailscale network**. Running from a Tailscale-connected device will show false positives.

### Requirements for Testing Machine

- **Linux VPS** (recommended) or **Linux workstation**
- **NOT connected** to the same Tailscale network (Tailnet) as your Proxmox server
- Must have: `nmap`, `curl`, `openssl`, `nikto` (for advanced testing)

### Basic Testing

```bash
# Run from external Linux machine (NOT on Tailscale)
./scripts/audit/security-test.sh YOUR_PUBLIC_IP yourdomain.com YOUR_TAILSCALE_IP
```

### Advanced Testing

```bash
# Run from external Linux machine (NOT on Tailscale)
./scripts/audit/advanced-security-test.sh YOUR_PUBLIC_IP yourdomain.com
```

**Expected Results:**
- ✅ Ports 22, 8006, 81: `FILTERED` (secured)
- ✅ Ports 80, 443: `OPEN` (correct for web services)

## 📊 Monitoring & Alerting

### Alert Levels

**Critical**: Services stopped, firewall disabled, disk space low  
**High**: Failed authentication attempts, exposed management ports  
**Medium**: Stopped containers, high connection count

### Email Configuration

Update email addresses in:
- `/etc/fail2ban/jail.local`
- `/etc/logwatch/conf/logwatch.conf`
- `/etc/apt/apt.conf.d/50unattended-upgrades`

### Log Locations

```bash
/var/log/proxmox-security/security.log    # Security monitoring
/var/log/fail2ban.log                     # Fail2Ban
/var/log/auth.log                         # Authentication
```

## 🔧 Troubleshooting

### NPM Not Accessible

```bash
pct status NPM_CONTAINER_ID                          # Check container
iptables -t nat -L PREROUTING -n -v --line-numbers   # Check NAT rules
```

### Tailscale Issues

```bash
tailscale status              # Check VPN status
ip addr show tailscale0       # Check IP
ping YOUR_TAILSCALE_IP        # Test connectivity
```

### Fail2Ban Not Blocking

```bash
fail2ban-client status               # Check status
fail2ban-client status sshd          # Check jail
tail -f /var/log/fail2ban.log        # View logs
```

### Emergency Recovery

```bash
# Temporary firewall disable (emergencies only!)
pve-firewall stop

# Restore previous configuration
proxmox-security-updates rollback
```

## 🎯 Best Practices

1. **Use Tailscale for management** - Never expose ports 22, 8006, 81 publicly
2. **Regular updates** - Run `proxmox-security-updates check` weekly
3. **Active monitoring** - Check status daily
4. **Regular backups** - Backup before major changes
5. **Periodic testing** - Run security tests monthly from external server
6. **Email alerts** - Configure for real-time notifications
7. **Log monitoring** - Check logs regularly
8. **Performance tracking** - Monitor CPU/RAM/Disk usage

## 🔗 External Resources

See [EXTERNAL_RESOURCES.md](EXTERNAL_RESOURCES.md) for 300+ curated links including:

- **Official Documentation**: Proxmox VE Wiki, Fail2Ban, Tailscale
- **Security Tools**: nmap, nikto, AppArmor, CIS Benchmarks
- **Community Resources**: Forums, tutorials, video guides
- **Best Practices**: OWASP, security standards, hardening guides

## 📞 Support

### Documentation
- [README.md](README.md) - Main documentation (English)
- [QUICKSTART.md](QUICKSTART.md) - Quick start guide
- [EXTERNAL_RESOURCES.md](EXTERNAL_RESOURCES.md) - External documentation links
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Project organization

### Getting Help
1. Check project documentation
2. Consult [Proxmox Wiki](https://pve.proxmox.com/wiki/Main_Page)
3. Search [Proxmox Forum](https://forum.proxmox.com/)
4. Open a [GitHub Issue](https://github.com/WarezNT/proxmox-security-suite/issues)

### Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### License

MIT License - see [LICENSE](LICENSE) for details.

---

**⚠️ Important**: This security suite is a powerful tool, but does not replace good security practices and responsible administration. Test all configurations in a development environment before applying to production.

**Repository**: https://github.com/WarezNT/proxmox-security-suite  
**Version**: 1.0.0  
**Last Updated**: October 5, 2025
