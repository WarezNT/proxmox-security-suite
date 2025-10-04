# Security Scripts

This directory contains all security scripts for Proxmox Security Suite, organized by function.

## 📁 Directory Structure

```
scripts/
├── core/                           # Core security operations
│   ├── security-hardening.sh       # System hardening wizard
│   ├── security-monitor.sh         # Real-time monitoring daemon
│   └── security-updates.sh         # Automated update management
└── audit/                          # Security testing & auditing
    ├── security-test.sh            # Basic security testing
    └── advanced-security-test.sh   # Advanced penetration testing
```

---

## 🔧 Core Scripts (`core/`)

Core scripts handle day-to-day security operations and maintenance.

### `security-hardening.sh`
Interactive system hardening wizard.

**Usage:**
```bash
sudo proxmox-security-hardening
# OR directly:
sudo /usr/local/share/proxmox-security/core/security-hardening.sh
```

**Features:**
- SSH hardening
- Fail2Ban configuration
- Per-container firewalls
- Kernel security optimizations
- AppArmor profiles

---

### `security-monitor.sh`
Real-time security monitoring with alerting.

**Usage:**
```bash
sudo systemctl start proxmox-security-monitor
sudo systemctl enable proxmox-security-monitor
sudo systemctl status proxmox-security-monitor
```

**Features:**
- Failed login monitoring
- Firewall change detection
- Resource usage alerts
- Critical service checks
- Email/webhook notifications

---

### `security-updates.sh`
Automated security update management.

**Usage:**
```bash
sudo proxmox-security-updates check      # Check for updates
sudo proxmox-security-updates security   # Apply security updates
sudo proxmox-security-updates all        # Update everything
sudo proxmox-security-updates backup     # Backup configs
sudo proxmox-security-updates rollback   # Rollback changes
```

**Features:**
- Automated update checking
- Security-only updates
- Container/VM updates
- Automatic backups
- Rollback capability

---

## 🔍 Audit Scripts (`audit/`)

⚠️ **CRITICAL**: Audit scripts **MUST** be run from an **external system** that is **NOT connected** to your Tailscale network.

**Supported Testing Platforms:**
- **Linux VPS** (DigitalOcean, Linode, Vultr, etc.) - **Recommended**
- **Linux workstation/laptop** (Ubuntu, Debian, Fedora, etc.)

**Requirements:**
- System must NOT be connected to the same Tailscale network (Tailnet)
- Basic tools: `curl`, `nc`, `openssl`
- Advanced tools: `nmap`, `nikto`, `dnsutils` (for advanced testing)

**Why External Testing?**  
If you test from a Tailscale-connected device, management ports (22, 8006, 81) will be accessible, showing **false positives**. External testing validates that public internet users cannot access your management interfaces.

### `security-test.sh`
Basic security testing from external perspective.

**Usage:**
```bash
# Download to external Linux VPS/workstation:
wget https://raw.githubusercontent.com/WarezNT/proxmox-security-suite/main/scripts/audit/security-test.sh
chmod +x security-test.sh

# Run test (NOT from Tailscale network):
./security-test.sh YOUR_PUBLIC_IP yourdomain.com YOUR_TAILSCALE_IP
```

**Tests:**
- Port accessibility (22, 80, 81, 443, 8006)
- SSL/TLS configuration
- Firewall effectiveness
- Fail2Ban protection
- Tailscale isolation

**Expected Results:**
- ✅ Port 22 (SSH): FILTERED
- ✅ Port 8006 (Proxmox): FILTERED
- ✅ Port 81 (NPM Admin): FILTERED
- ✅ Port 80 (HTTP): OPEN
- ✅ Port 443 (HTTPS): OPEN

---

### `advanced-security-test.sh`
Advanced penetration testing and vulnerability scanning.

**Usage:**
```bash
# Download to external Linux VPS/workstation:
wget https://raw.githubusercontent.com/WarezNT/proxmox-security-suite/main/scripts/audit/advanced-security-test.sh
chmod +x advanced-security-test.sh

# Install dependencies:
sudo apt install nmap nikto curl dnsutils -y

# Run test (NOT from Tailscale network):
./advanced-security-test.sh YOUR_PUBLIC_IP yourdomain.com
```

**Tests:**
- Comprehensive port scanning (nmap)
- Web vulnerability scanning (nikto)
- SSL/TLS deep analysis
- HTTP security headers
- DNS security features
- Rate limiting detection
- DDoS protection testing

**Duration:** 10-30 minutes  
**Output:** Detailed vulnerability report

---

## 🚀 Installation

These scripts are automatically installed when you run `setup.sh` from the repository root:

```bash
cd /tmp
wget https://raw.githubusercontent.com/WarezNT/proxmox-security-suite/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

The installer will:
1. Download all scripts from GitHub
2. Install them in `/usr/local/share/proxmox-security/`
3. Create command wrappers in `/usr/local/bin/` (prefixed with `proxmox-`)
4. Configure systemd services for monitoring

---

## ⚠️ Critical Testing Notes

### External Testing Requirements

**IMPORTANT:** Audit scripts (`audit/` folder) must be run from an external VPS that is **NOT connected to your Tailscale network**.

**Why?**
- Testing from within Tailscale will show false positives
- Management ports will appear accessible when they shouldn't be
- Results will not reflect real-world public exposure

**Correct Testing Setup:**
1. Use a separate VPS (DigitalOcean, Linode, Vultr, etc.)
2. Ensure it's NOT connected to your Tailscale network
3. Run audit scripts from there to get accurate results

**Verification:**
```bash
# On test VPS, check for Tailscale:
ip route show | grep "100\."

# Should return nothing - if it shows Tailscale routes, disconnect first!
```

---

## 📖 Documentation

For complete documentation, see:
- [README.md](../README.md) - Main documentation (English)
- [QUICKSTART.md](../QUICKSTART.md) - Quick start guide
- [EXTERNAL_RESOURCES.md](../EXTERNAL_RESOURCES.md) - External resources
- [PROJECT_STRUCTURE.md](../PROJECT_STRUCTURE.md) - Project organization

---

## 🔗 Links

- **Repository:** https://github.com/WarezNT/proxmox-security-suite
- **Issues:** https://github.com/WarezNT/proxmox-security-suite/issues
- **License:** MIT

---

**Note:** These scripts require root privileges and modify system configuration. Always test in a non-production environment first.
