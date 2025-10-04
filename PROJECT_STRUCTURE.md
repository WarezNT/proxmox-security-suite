# 📁 Proxmox Security Suite - Project Structure

## 🌳 Directory Organization

```
proxmox-security-suite/
├── 📄 setup.sh                           # Main installer script
├── 📁 scripts/                           # All security scripts
│   ├── 📁 core/                          # Core security operations
│   │   ├── 🔧 security-hardening.sh      # System hardening wizard
│   │   ├── 📊 security-monitor.sh        # Real-time monitoring daemon
│   │   └── 🔄 security-updates.sh        # Automated update management
│   ├── 📁 audit/                         # Security testing & auditing
│   │   ├── 🧪 security-test.sh           # Basic security testing
│   │   └── 🔬 advanced-security-test.sh  # Advanced penetration testing
│   └── 📖 README.md                      # Scripts documentation
├── 📚 README.md                          # Main documentation (English)
├── 📚 README.ro.md                       # Romanian documentation
├── 🚀 QUICKSTART.md                      # Quick start guide
├── 🔗 EXTERNAL_RESOURCES.md              # 300+ curated external resources
├── 🤝 CONTRIBUTING.md                    # Contribution guidelines
├── 📝 CHANGELOG.md                       # Version history
├── 📋 PROJECT_STRUCTURE.md               # This file
├── ⚖️ LICENSE                            # MIT License
├── 🚫 .gitignore                         # Git exclusions
└── 📁 .github/                           # GitHub config (local only)
    └── copilot-instructions.md           # AI development instructions (not tracked)
```

## 📊 Statistics

- **Total public files:** 18 (10 root + 6 scripts/ + 2 config)
- **Scripts:** 6 (1 installer + 3 core + 2 audit)
- **Documentation:** 8 files (6 root + 1 scripts/README + 1 PROJECT_STRUCTURE)
- **Configuration:** 2 files (.gitignore, LICENSE)
- **Lines of code:** ~3,500+
- **External resources:** 300+ curated links

## 📝 Detailed Descriptions

### 🔧 Scripts

#### `setup.sh` (Root Level)
**Role:** Main installation script - system entry point

**Functions:**
- Validates Proxmox VE environment
- Downloads all scripts from GitHub (`scripts/core/` and `scripts/audit/`)
- Installs dependencies (Fail2Ban, iptables-persistent, monitoring tools)
- Configures multi-layer firewalls
- Creates system command wrappers (`proxmox-security-*`)
- Sets up systemd services for automated monitoring
- Backs up existing configurations

**Usage:**
```bash
cd /tmp
wget https://raw.githubusercontent.com/WarezNT/proxmox-security-suite/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

**Size:** ~400 lines  
**Duration:** 2-5 minutes complete installation

---

### 📁 scripts/core/ - Core Security Operations

#### `security-hardening.sh`
**Role:** Interactive system hardening wizard

**Features:**
- SSH hardening (disable root login, key-only authentication)
- Fail2Ban setup with custom Proxmox and NPM filters
- Per-container firewall configuration
- Kernel security optimizations
- AppArmor profiles for containers
- Security headers for web services
- Rate limiting and DDoS protection

**Usage:**
```bash
sudo proxmox-security-hardening
# OR directly:
sudo /usr/local/share/proxmox-security/core/security-hardening.sh
```

**Mode:** Interactive wizard  
**Size:** ~450 lines

---

#### `security-monitor.sh`
**Role:** Real-time security monitoring daemon

**Features:**
- Failed login attempt monitoring
- Firewall change detection
- Suspicious traffic alerting
- Resource usage monitoring (CPU, RAM, disk)
- Critical service status checks
- Log aggregation and analysis
- Email/webhook notifications

**Usage:**
```bash
# Start as systemd service:
sudo systemctl start proxmox-security-monitor
sudo systemctl enable proxmox-security-monitor

# Check status:
sudo systemctl status proxmox-security-monitor

# View logs:
sudo journalctl -u proxmox-security-monitor -f
```

**Mode:** Background daemon  
**Size:** ~400 lines

---

#### `security-updates.sh`
**Role:** Automated security update management

**Features:**
- Check available updates (Proxmox + Debian)
- Apply security-only updates
- Update LXC containers and VMs
- Automatic backup before updates
- Rollback capability on failure
- Email notifications for important updates
- Scheduled cron jobs

**Usage:**
```bash
# Check for updates:
sudo proxmox-security-updates check

# Apply security updates only:
sudo proxmox-security-updates security

# Update all packages:
sudo proxmox-security-updates all

# Backup before changes:
sudo proxmox-security-updates backup

# Rollback to previous state:
sudo proxmox-security-updates rollback
```

**Mode:** CLI tool + cron automation  
**Size:** ~350 lines

---

### 📁 scripts/audit/ - Security Testing & Auditing

#### `security-test.sh`
**Role:** Basic security testing (run from external VPS)

**Features:**
- Port scanning (22, 80, 81, 443, 8006) - verify public exposure
- SSL/TLS configuration testing
- Firewall rule validation
- Fail2Ban effectiveness testing
- Basic vulnerability scanning
- Tailscale isolation verification

**Usage:**
```bash
# From external VPS (NOT on Tailscale):
./scripts/audit/security-test.sh YOUR_PUBLIC_IP yourdomain.com YOUR_TAILSCALE_IP

# Expected output:
# ✅ Port 22 (SSH): FILTERED
# ✅ Port 8006 (Proxmox): FILTERED
# ✅ Port 81 (NPM): FILTERED
# ✅ Port 80 (HTTP): OPEN
# ✅ Port 443 (HTTPS): OPEN
```

**CRITICAL:** Must run from VPS NOT connected to same Tailscale network!  
**Size:** ~300 lines

---

#### `advanced-security-test.sh`
**Role:** Advanced penetration testing (external VPS only)

**Features:**
- Comprehensive nmap port scanning
- Web vulnerability scanning with nikto
- Deep SSL/TLS protocol analysis
- HTTP security headers assessment
- DNS security feature detection (DNSSEC, CAA)
- Rate limiting detection
- DDoS protection testing
- Comprehensive vulnerability report

**Usage:**
```bash
# From external VPS only:
./scripts/audit/advanced-security-test.sh YOUR_PUBLIC_IP yourdomain.com

# Prerequisites:
sudo apt install nmap nikto curl dnsutils -y
```

**Duration:** 10-30 minutes  
**Output:** Detailed HTML + terminal report  
**Size:** ~500 lines

---

### 📚 Documentation

#### `README.md` (English)
**Role:** Primary project documentation

**Content:**
- Project overview with competitive positioning
- Comparison table vs alternatives
- Security architecture diagrams
- Step-by-step installation guide
- Complete script descriptions
- Detailed configuration (firewall, NPM, Tailscale)
- Usage examples
- Security best practices
- Comprehensive troubleshooting
- External resource references

**Language:** English  
**Size:** ~650 lines  
**Audience:** All users

---

#### `README.ro.md` (Romanian)
**Role:** Romanian language documentation

**Content:** Same as README.md but in Romanian  
**Language:** Romanian  
**Size:** ~650 lines

---

#### `QUICKSTART.md`
**Role:** Quick "copy-paste" guide for beginners

**Content:**
- 15-minute complete setup
- Ready-to-copy commands
- Minimal required configurations
- Quick verification steps
- Links to official documentation
- Common pitfalls and solutions

**Format:** Step-by-step with checkboxes  
**Size:** ~200 lines  
**Target:** New users, zero-to-hero path

---

#### `EXTERNAL_RESOURCES.md`
**Role:** Centralized hub of 300+ curated external links

**Categories:**
1. **Proxmox Official** - Official documentation
2. **Security Tools** - Fail2Ban, iptables, AppArmor
3. **Networking** - Tailscale, Cloudflare, DNS
4. **Monitoring** - systemd, journald, logging
5. **Testing** - nmap, nikto, security scanners
6. **Best Practices** - OWASP, CIS benchmarks
7. **Community** - Forums, Reddit, Discord
8. **Video Tutorials** - YouTube channels
9. **Books & Courses** - Learning resources
10. **Tools & Software** - Recommended security tools
11. **Proxmox-Specific** - LXC, firewall, networking

**Format:** Organized markdown with links  
**Size:** ~600 lines  
**Value:** Complete educational platform

---

#### `CONTRIBUTING.md`
**Role:** Open-source contributor guide

**Content:**
- How to contribute (issues, pull requests)
- Coding standards (bash best practices)
- Testing requirements
- Documentation guidelines
- Commit message format
- Code of conduct
- License information

**Size:** ~150 lines

---

#### `CHANGELOG.md`
**Role:** Complete change history

**Format:** Keep a Changelog standard  
**Content:**
- Versions (Semantic Versioning)
- Added / Changed / Fixed / Removed
- Release dates
- Breaking changes

**Size:** ~100 lines (will grow)

---

#### `scripts/README.md`
**Role:** Scripts folder documentation

**Content:**
- Overview of core/ and audit/ folders
- Quick usage examples
- Installation instructions
- Links to main documentation

**Size:** ~100 lines

---

### ⚙️ Configuration

#### `.gitignore`
**Role:** Prevents data leaks and tracks only essential files

**Excludes:**
```gitignore
# AI Development Files (local only)
.github/copilot-instructions.md
*-ai-*.md
*.ai.md

# Sensitive Data
*.key
*.pem
*.crt
secrets/
*.secret
*.password

# Logs
*.log
logs/

# Backups
*.backup
backups/

# Temporary
*.tmp
tmp/
.DS_Store
```

**Importance:** CRITICAL - protects personal data

---

#### `LICENSE`
**Type:** MIT License

**Allows:**
- ✅ Commercial use
- ✅ Modification
- ✅ Distribution
- ✅ Private use

**Requirements:**
- Copyright notice
- License inclusion

---

### 📁 .github/ (Local Only)

#### `copilot-instructions.md`
**Role:** Instructions for GitHub Copilot / AI assistants

**Content:**
- Project architecture
- Network configuration details
- Security model explained
- Common operations
- Troubleshooting guides
- Personal IP addresses and configurations

**Status:** ❌ NOT tracked in Git (in .gitignore)  
**Usage:** Local development with AI only  
**Size:** ~500 lines

---

## 🔄 User Journey

### 1️⃣ Discovery
User finds project on GitHub:
- **README.md** → Overview, competitive advantages
- **Badges** → Check license, supported Proxmox version

### 2️⃣ Evaluation
Decides if project fits needs:
- **Comparison table** → See unique features vs alternatives
- **EXTERNAL_RESOURCES.md** → Verify backed by official docs

### 3️⃣ Quick Installation
Beginner wants quick setup:
- **QUICKSTART.md** → 15-minute setup
- **setup.sh** → One command, automated install

### 4️⃣ Detailed Configuration
Power user wants customization:
- **README.md** → Detailed configuration
- **scripts/** → Run scripts individually
- **EXTERNAL_RESOURCES.md** → Learn about each component

### 5️⃣ Maintenance
Daily usage:
- **security-monitor.sh** → Runs automatically (systemd)
- **security-updates.sh** → Automated updates
- **CHANGELOG.md** → Check what's new

### 6️⃣ Troubleshooting
Issues arise:
- **README.md** → Troubleshooting section
- **EXTERNAL_RESOURCES.md** → Links to official documentation
- **GitHub Issues** → Community support

### 7️⃣ Contribution
Wants to improve project:
- **CONTRIBUTING.md** → Contribution guide
- **Pull Request** → Propose improvements

---

## 📊 Quality Metrics

### Code Quality
- ✅ **Bash Best Practices:** shellcheck compliance
- ✅ **Error Handling:** Comprehensive error management
- ✅ **Logging:** Detailed logging in all scripts
- ✅ **Comments:** Code documentation
- ✅ **Modularity:** Reusable functions

### Documentation Quality
- ✅ **Completeness:** All features documented
- ✅ **Clarity:** Clear language, step-by-step
- ✅ **Examples:** Copy-paste ready commands
- ✅ **External Links:** 300+ curated resources
- ✅ **Bilingual:** English + Romanian

### User Experience
- ✅ **Quick Start:** 15-minute setup
- ✅ **One-Command Install:** `sudo ./setup.sh`
- ✅ **Interactive Wizards:** User-friendly prompts
- ✅ **Full Automation:** 100% automated security
- ✅ **Real-time Monitoring:** Instant alerts

### Security Standards
- ✅ **Multi-Layer Firewall:** Proxmox + Container + iptables
- ✅ **VPN Isolation:** Management via Tailscale only
- ✅ **Fail2Ban:** Automated intrusion prevention
- ✅ **SSL/TLS:** Cloudflare + NPM certificates
- ✅ **Testing:** Basic + Advanced security scans

---

## 🚀 Development Workflow

### Optimized Structure
```
Root Level:
  └── setup.sh          ← Entry point (downloads & installs everything)

scripts/core/:
  ├── security-hardening.sh
  ├── security-monitor.sh
  └── security-updates.sh

scripts/audit/:
  ├── security-test.sh
  └── advanced-security-test.sh
```

### Structure Advantages
1. **Clarity:** `setup.sh` is obvious first script
2. **Organization:** Core operations vs audit separated
3. **Modularity:** Easy to add new scripts
4. **GitHub URLs:** Easy to reference: `.../scripts/core/*.sh`
5. **Maintenance:** Clear folder structure for updates

---

## 📌 Important Notes

### For Users
- Always start with `setup.sh` - downloads everything needed
- Scripts install automatically as system commands
- After install, use `proxmox-security-*` commands (no paths needed)

### For Developers
- DO NOT create `*-ai-*.md` or `*.ai.md` files - these are in `.gitignore`
- DO NOT create status/completion/summary files - internal only
- Keep `.github/copilot-instructions.md` LOCAL ONLY (not tracked)
- Public files must be user-facing, not development artifacts

### For GitHub Release
Repository contains:
- ✅ 18 public files (10 root + 6 scripts/ + 2 folders)
- ✅ Complete documentation in English + Romanian
- ✅ 300+ links to external resources
- ✅ Zero internal/temporary files
- ✅ Clean, professional structure

---

**Last updated:** October 5, 2025  
**Version:** 1.0.0  
**Repository:** https://github.com/WarezNT/proxmox-security-suite  
**Status:** ✅ Production-Ready
