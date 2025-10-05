#!/bin/bash

# Proxmox Security Suite - Main Installer
# Downloads all scripts from GitHub and installs the complete security suite
# Usage: sudo ./setup.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
SCRIPTS_DIR="/usr/local/share/proxmox-security"
BIN_DIR="/usr/local/bin"
GITHUB_RAW="https://raw.githubusercontent.com/WarezNT/proxmox-security-suite/main"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Proxmox Security Suite - Installation Script         ║${NC}"
echo -e "${BLUE}║              https://github.com/WarezNT                      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo

# Display disclaimer
echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║                        DISCLAIMER                             ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${RED}USE AT YOUR OWN RISK${NC}"
echo
echo -e "${YELLOW}This software is provided 'as is' without warranty of any kind.${NC}"
echo -e "${YELLOW}The authors are NOT LIABLE for any damages or security issues.${NC}"
echo -e "${YELLOW}Always test in non-production environment first!${NC}"
echo
echo -e "${YELLOW}By continuing, you acknowledge that you:${NC}"
echo -e "${YELLOW}  • Understand the risks of modifying security configurations${NC}"
echo -e "${YELLOW}  • Have adequate backups of your system${NC}"
echo -e "${YELLOW}  • Accept full responsibility for any consequences${NC}"
echo
read -p "Do you accept these terms and wish to continue? (yes/NO) " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${RED}Installation cancelled by user.${NC}"
    exit 0
fi
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}" 
   exit 1
fi

# Verify Proxmox environment
if ! command -v pveversion &> /dev/null; then
    echo -e "${YELLOW}Warning: pveversion not found. This may not be a Proxmox server.${NC}"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${BLUE}Step 1/5: Creating directories...${NC}"
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$BIN_DIR"
echo -e "${GREEN}[OK] Directories created${NC}"
echo

echo -e "${BLUE}Step 2/5: Downloading core security scripts...${NC}"

# Download only core scripts (these run on Proxmox host)
CORE_SCRIPTS=(
    "security-hardening.sh"
    "security-monitor.sh"
    "security-updates.sh"
)

mkdir -p "$SCRIPTS_DIR/core"

for script in "${CORE_SCRIPTS[@]}"; do
    echo -e "${YELLOW}  Downloading core/$script...${NC}"
    if wget -q "$GITHUB_RAW/scripts/core/$script" -O "$SCRIPTS_DIR/core/$script"; then
        chmod +x "$SCRIPTS_DIR/core/$script"
        echo -e "${GREEN}  [OK] $script downloaded${NC}"
    else
        echo -e "${RED}  [X] Failed to download $script${NC}"
        echo -e "${YELLOW}  Trying local copy...${NC}"
        if [ -f "scripts/core/$script" ]; then
            cp "scripts/core/$script" "$SCRIPTS_DIR/core/$script"
            chmod +x "$SCRIPTS_DIR/core/$script"
            echo -e "${GREEN}  [OK] Copied local $script${NC}"
        else
            echo -e "${RED}  [X] Local copy not found${NC}"
            exit 1
        fi
    fi
done

echo
echo -e "${BLUE}Note: Audit scripts (security-test.sh, advanced-security-test.sh)${NC}"
echo -e "${BLUE}must be downloaded and run from an external VPS, NOT on Proxmox host.${NC}"
echo -e "${BLUE}See documentation for details.${NC}"
echo
echo -e "${GREEN}[OK] All scripts downloaded${NC}"
echo

echo -e "${BLUE}Step 3/5: Installing dependencies...${NC}"
apt-get update -qq

# Set non-interactive mode to avoid prompts (especially for iptables-persistent)
export DEBIAN_FRONTEND=noninteractive

apt-get install -y -qq \
    fail2ban \
    iptables \
    iptables-persistent \
    unattended-upgrades \
    apt-listchanges \
    logwatch \
    curl \
    wget \
    nmap \
    &> /dev/null

# Unset DEBIAN_FRONTEND
unset DEBIAN_FRONTEND

echo -e "${GREEN}[OK] Dependencies installed${NC}"
echo

echo -e "${BLUE}Step 4/5: Creating command wrappers...${NC}"

# Create wrapper commands for core scripts only
for script in "${CORE_SCRIPTS[@]}"; do
    script_name="${script%.sh}"
    wrapper_name="proxmox-$script_name"
    
    cat > "$BIN_DIR/$wrapper_name" << EOF
#!/bin/bash
exec "$SCRIPTS_DIR/core/$script" "\$@"
EOF
    
    chmod +x "$BIN_DIR/$wrapper_name"
    echo -e "${GREEN}  [OK] Created command: $wrapper_name${NC}"
done

echo -e "${GREEN}[OK] Command wrappers created${NC}"
echo

echo -e "${BLUE}Step 5/5: Setting up monitoring service...${NC}"

# Create systemd service for monitoring
cat > /etc/systemd/system/proxmox-security-monitor.service << 'EOF'
[Unit]
Description=Proxmox Security Monitoring Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/share/proxmox-security/core/security-monitor.sh daemon
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

echo -e "${GREEN}[OK] Monitoring service installed${NC}"
echo

echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              Installation completed successfully!             ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${BLUE}Available Commands (on Proxmox host):${NC}"
echo -e "  ${GREEN}proxmox-security-hardening${NC}  - Interactive security hardening"
echo -e "  ${GREEN}proxmox-security-monitor${NC}    - Security monitoring & alerts"
echo -e "  ${GREEN}proxmox-security-updates${NC}    - Update management"
echo
echo -e "${BLUE}Security Testing (run from external VPS):${NC}"
echo -e "  Download audit scripts manually:"
echo -e "  ${YELLOW}wget https://raw.githubusercontent.com/WarezNT/proxmox-security-suite/main/scripts/audit/security-test.sh${NC}"
echo -e "  ${YELLOW}wget https://raw.githubusercontent.com/WarezNT/proxmox-security-suite/main/scripts/audit/advanced-security-test.sh${NC}"
echo -e "  ${YELLOW}chmod +x *.sh${NC}"
echo
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Start monitoring: ${GREEN}sudo systemctl start proxmox-security-monitor${NC}"
echo -e "  2. Enable on boot: ${GREEN}sudo systemctl enable proxmox-security-monitor${NC}"
echo -e "  3. Check status: ${GREEN}proxmox-security-monitor status${NC}"
echo
echo -e "${YELLOW}IMPORTANT: Configure email addresses in:${NC}"
echo -e "  - /etc/fail2ban/jail.local"
echo -e "  - /etc/logwatch/conf/logwatch.conf"
echo -e "  - /etc/apt/apt.conf.d/50unattended-upgrades"
echo
echo -e "${BLUE}For detailed documentation, visit:${NC}"
echo -e "  ${GREEN}https://github.com/WarezNT/proxmox-security-suite${NC}"
echo

# Check if user wants to start monitoring now
read -p "Start security monitoring now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    systemctl start proxmox-security-monitor
    systemctl enable proxmox-security-monitor
    echo -e "${GREEN}[OK] Security monitoring started and enabled${NC}"
else
    echo -e "${GREEN}[OK] Run 'sudo systemctl start proxmox-security-monitor' when ready${NC}"
fi

echo
echo -e "${GREEN}Installation complete! Run 'proxmox-security-hardening' to begin.${NC}"
