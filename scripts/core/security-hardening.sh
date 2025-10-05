#!/bin/bash

# Proxmox Security Hardening Script
# Run this script on the Proxmox host to implement advanced security measures
# Usage: sudo ./security-hardening.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}    Proxmox Security Hardening Script${NC}"
echo -e "${BLUE}============================================${NC}"
echo

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (sudo)${NC}"
    exit 1
fi

# Function to install fail2ban
install_fail2ban() {
    echo -e "${YELLOW}Installing and configuring Fail2Ban...${NC}"
    
    apt update && apt install -y fail2ban
    
    # Create custom jail configuration
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[proxmox]
enabled = true
port = 8006
filter = proxmox
logpath = /var/log/daemon.log
maxretry = 3
bantime = 7200

[nginx-noproxy]
enabled = false
port = 80,443
filter = nginx-noproxy
logpath = /var/log/nginx/access.log
maxretry = 5
EOF

    # Create Proxmox filter
    cat > /etc/fail2ban/filter.d/proxmox.conf << 'EOF'
[Definition]
failregex = pvedaemon\[.*authentication failure; rhost=<HOST>
ignoreregex =
EOF

    systemctl enable fail2ban
    systemctl restart fail2ban
    
    echo -e "${GREEN}✓ Fail2Ban configured${NC}"
}

# Function to configure container firewall
configure_container_firewall() {
    echo -e "${YELLOW}Configuring container-level firewalls...${NC}"
    echo
    
    # Prompt for NPM container ID
    read -p "Enter your NPM container ID (e.g., 100, 600): " NPM_CONTAINER_ID
    
    # Enable firewall for NPM container
    if pct list | grep -q "^${NPM_CONTAINER_ID}"; then
        echo -e "${BLUE}Detecting network configuration...${NC}"
        
        # Detect private network from bridges
        PRIVATE_NETWORK=$(ip addr show | grep -oP 'inet \K10\.\d+\.\d+\.\d+/\d+' | head -1)
        if [ -z "$PRIVATE_NETWORK" ]; then
            PRIVATE_NETWORK="10.10.0.0/24"
        fi
        
        # Detect Tailscale network
        TAILSCALE_NETWORK=$(ip addr show tailscale0 2>/dev/null | grep -oP 'inet \K100\.\d+\.\d+\.\d+/\d+' | head -1)
        if [ -z "$TAILSCALE_NETWORK" ]; then
            TAILSCALE_NETWORK="100.64.0.0/10"  # Default Tailscale CGNAT range
        else
            # Extract network from Tailscale IP (keep /10 for full range)
            TAILSCALE_NETWORK="100.64.0.0/10"
        fi
        
        echo
        echo -e "${YELLOW}Detected network configuration:${NC}"
        echo -e "  Private Network: ${GREEN}${PRIVATE_NETWORK}${NC}"
        echo -e "  Tailscale Network: ${GREEN}${TAILSCALE_NETWORK}${NC}"
        echo
        read -p "Use these networks? (Y/n): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo
            read -p "Enter your private network (e.g., 10.10.0.0/24): " PRIVATE_NETWORK
            read -p "Enter your Tailscale network (e.g., 100.64.0.0/10): " TAILSCALE_NETWORK
        fi
        
        pct set ${NPM_CONTAINER_ID} -firewall 1
        
        # Create firewall rules for NPM with detected/confirmed networks
        cat > /etc/pve/firewall/${NPM_CONTAINER_ID}.fw << EOF
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT
log_level_in: info

[RULES]
# Allow HTTP/HTTPS from private network
IN ACCEPT -source ${PRIVATE_NETWORK} -dport 80,443
# Allow NPM admin from Tailscale network
IN ACCEPT -source ${TAILSCALE_NETWORK} -dport 81
# Allow ICMP for monitoring
IN ACCEPT -p icmp
# Log and drop everything else
IN DROP -log warning
EOF
        echo -e "${GREEN}✓ NPM container (${NPM_CONTAINER_ID}) firewall configured${NC}"
        echo -e "${BLUE}  Private Network: ${PRIVATE_NETWORK}${NC}"
        echo -e "${BLUE}  Tailscale Network: ${TAILSCALE_NETWORK}${NC}"
    else
        echo -e "${YELLOW}⚠ Container ${NPM_CONTAINER_ID} not found, skipping${NC}"
    fi
}

# Function to setup network monitoring
setup_monitoring() {
    echo -e "${YELLOW}Setting up network monitoring...${NC}"
    
    # Install monitoring tools
    apt install -y iftop netstat-nat tcpdump
    
    # Create network monitoring script
    cat > /usr/local/bin/network-monitor.sh << 'EOF'
#!/bin/bash
# Simple network monitoring for Proxmox

LOG_FILE="/var/log/network-monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Monitor for unusual connections to management ports
netstat -tuln | grep -E ':22|:8006|:81' | while read line; do
    echo "[$DATE] Management port activity: $line" >> $LOG_FILE
done

# Monitor bridge traffic
if command -v iftop >/dev/null 2>&1; then
    timeout 10 iftop -i PRIV -t -s 10 >> $LOG_FILE 2>/dev/null
fi
EOF

    chmod +x /usr/local/bin/network-monitor.sh
    
    # Add to cron for regular monitoring
    (crontab -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/network-monitor.sh") | crontab -
    
    echo -e "${GREEN}✓ Network monitoring configured${NC}"
}

# Function to setup backup security
setup_backup_security() {
    echo -e "${YELLOW}Configuring backup security...${NC}"
    
    # Create backup user with limited permissions
    pveum user add backup@pve --comment "Backup automation user"
    pveum role add BackupOperator --privs "VM.Backup,Datastore.Allocate,Datastore.AllocateSpace"
    pveum acl modify / --users backup@pve --role BackupOperator
    
    # Set password for backup user (you should change this)
    echo "backup@pve:$(openssl rand -base64 12)" | chpasswd
    
    echo -e "${GREEN}✓ Backup security configured${NC}"
    echo -e "${YELLOW}Remember to change the backup user password!${NC}"
}

# Function to harden SSH
harden_ssh() {
    echo -e "${YELLOW}Hardening SSH configuration...${NC}"
    
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Apply SSH hardening (only if not already configured)
    if ! grep -q "# Proxmox Security Hardening" /etc/ssh/sshd_config; then
        cat >> /etc/ssh/sshd_config << 'EOF'

# Proxmox Security Hardening
Protocol 2
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
        systemctl restart sshd
        echo -e "${GREEN}✓ SSH hardened${NC}"
    else
        echo -e "${YELLOW}⚠ SSH already hardened${NC}"
    fi
}

# Function to setup log monitoring
setup_log_monitoring() {
    echo -e "${YELLOW}Setting up log monitoring...${NC}"
    echo
    
    # Prompt for email configuration
    read -p "Enter admin email address for log reports: " ADMIN_EMAIL
    if [ -z "$ADMIN_EMAIL" ]; then
        ADMIN_EMAIL="admin@yourdomain.com"
        echo -e "${YELLOW}Using default: ${ADMIN_EMAIL}${NC}"
    fi
    
    read -p "Enter sender email address (or press Enter for root@$(hostname)): " FROM_EMAIL
    if [ -z "$FROM_EMAIL" ]; then
        FROM_EMAIL="root@$(hostname -f)"
    fi
    
    # Install logwatch for log analysis
    apt install -y logwatch
    
    # Configure logwatch with user-provided emails
    cat > /etc/logwatch/conf/logwatch.conf << EOF
LogDir = /var/log
MailTo = ${ADMIN_EMAIL}
MailFrom = ${FROM_EMAIL}
Detail = Med
Service = All
Range = yesterday
Output = mail
Format = text
EOF

    # Create log rotation for security logs
    cat > /etc/logrotate.d/security << 'EOF'
/var/log/fail2ban.log {
    daily
    missingok
    rotate 30
    compress
    notifempty
    create 644 root root
    postrotate
        systemctl reload fail2ban > /dev/null 2>&1 || true
    endscript
}
EOF

    echo -e "${GREEN}✓ Log monitoring configured${NC}"
    echo -e "${BLUE}  Reports will be sent to: ${ADMIN_EMAIL}${NC}"
}

# Function to create security check script
create_security_checker() {
    echo -e "${YELLOW}Creating security check script...${NC}"
    echo
    
    # Prompt for email if not already set
    if [ -z "$ADMIN_EMAIL" ]; then
        read -p "Enter admin email address for security reports: " ADMIN_EMAIL
        if [ -z "$ADMIN_EMAIL" ]; then
            ADMIN_EMAIL="admin@yourdomain.com"
            echo -e "${YELLOW}Using default: ${ADMIN_EMAIL}${NC}"
        fi
    fi
    
    cat > /usr/local/bin/security-check.sh << 'EOF'
#!/bin/bash
# Daily security check script

echo "=== Proxmox Security Check - $(date) ==="

# Check fail2ban status
echo "Fail2Ban Status:"
fail2ban-client status
echo

# Check for unusual network connections
echo "Unusual connections to management ports:"
netstat -tuln | grep -E ':22|:8006|:81'
echo

# Check firewall status
echo "Firewall Status:"
pve-firewall status
echo

# Check for failed authentication attempts
echo "Recent failed auth attempts:"
tail -20 /var/log/auth.log | grep "authentication failure"
echo

# Check container status
echo "Container Status:"
pct list
echo

# Check system updates
echo "Available updates:"
apt list --upgradable 2>/dev/null | wc -l
echo
EOF

    chmod +x /usr/local/bin/security-check.sh
    
    # Add to daily cron with user-provided email
    (crontab -l 2>/dev/null; echo "0 6 * * * /usr/local/bin/security-check.sh | mail -s 'Proxmox Security Report' ${ADMIN_EMAIL}") | crontab -
    
    echo -e "${GREEN}✓ Security check script created${NC}"
    echo -e "${BLUE}  Daily reports will be sent to: ${ADMIN_EMAIL}${NC}"
}

# Main menu
main_menu() {
    echo "Select security hardening options:"
    echo "1) Install and configure Fail2Ban"
    echo "2) Configure container-level firewalls"
    echo "3) Setup network monitoring"
    echo "4) Configure backup security"
    echo "5) Harden SSH configuration"
    echo "6) Setup log monitoring"
    echo "7) Create security check script"
    echo "8) All of the above"
    echo "9) Exit"
    echo
    read -p "Enter your choice (1-9): " choice
    
    case $choice in
        1) install_fail2ban ;;
        2) configure_container_firewall ;;
        3) setup_monitoring ;;
        4) setup_backup_security ;;
        5) harden_ssh ;;
        6) setup_log_monitoring ;;
        7) create_security_checker ;;
        8) 
            install_fail2ban
            configure_container_firewall
            setup_monitoring
            setup_backup_security
            harden_ssh
            setup_log_monitoring
            create_security_checker
            ;;
        9) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
}

# Run main menu
main_menu

echo
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}    Security Hardening Complete!${NC}"
echo -e "${BLUE}============================================${NC}"
echo
echo -e "${GREEN}Next steps:${NC}"
echo "1. Update email addresses in log monitoring configs"
echo "2. Test fail2ban: fail2ban-client status"
echo "3. Review firewall rules: pve-firewall status"
echo "4. Run security check: /usr/local/bin/security-check.sh"
echo "5. Monitor logs: tail -f /var/log/fail2ban.log"
echo
echo -e "${YELLOW}Remember to:${NC}"
echo "• Change default backup user password"
echo "• Configure email settings for alerts"
echo "• Test all services after applying changes"
echo "• Keep Proxmox and containers updated"