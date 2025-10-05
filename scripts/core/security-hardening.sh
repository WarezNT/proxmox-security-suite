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
        
        # Create firewall rules for NPM with detected/confirmed networks
        # Note: Creating the .fw file automatically enables the firewall for the container
        cat > /etc/pve/firewall/${NPM_CONTAINER_ID}.fw << EOF
[OPTIONS]
enable: 1
policy_in: DROP
policy_out: ACCEPT
log_level_in: info

[RULES]
# Allow HTTP/HTTPS from private network
IN ACCEPT -source ${PRIVATE_NETWORK} -dport 80,443 -proto tcp
# Allow NPM admin from Tailscale network
IN ACCEPT -source ${TAILSCALE_NETWORK} -dport 81 -proto tcp
# Allow ICMP (ping) for monitoring
IN ACCEPT -proto icmp
# Log and drop everything else
IN DROP -log warning
EOF
        
        # Validate the firewall configuration
        echo
        echo -e "${BLUE}Validating firewall configuration...${NC}"
        if pve-firewall compile 2>&1 | grep -q "error"; then
            echo -e "${RED}✗ Firewall configuration has errors!${NC}"
            pve-firewall compile 2>&1
        else
            echo -e "${GREEN}✓ Firewall configuration is valid${NC}"
        fi
        
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
    
    # Prompt for email configuration with validation
    while true; do
        read -p "Enter admin email address for log reports: " ADMIN_EMAIL
        if [ -n "$ADMIN_EMAIL" ]; then
            # Check if it looks like an email
            if echo "$ADMIN_EMAIL" | grep -qE '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; then
                break
            else
                echo -e "${RED}Invalid email format. Please try again.${NC}"
            fi
        else
            echo -e "${YELLOW}Email address is required. Please enter a valid email.${NC}"
        fi
    done
    
    read -p "Enter sender email address (or press Enter for root@$(hostname -f)): " FROM_EMAIL
    if [ -z "$FROM_EMAIL" ]; then
        FROM_EMAIL="root@$(hostname -f)"
        echo -e "${BLUE}Using: ${FROM_EMAIL}${NC}"
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
    
    # Prompt for email if not already set from previous function
    if [ -z "$ADMIN_EMAIL" ]; then
        while true; do
            read -p "Enter admin email address for security reports: " ADMIN_EMAIL
            if [ -n "$ADMIN_EMAIL" ]; then
                # Check if it looks like an email
                if echo "$ADMIN_EMAIL" | grep -qE '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; then
                    break
                else
                    echo -e "${RED}Invalid email format. Please try again.${NC}"
                fi
            else
                echo -e "${YELLOW}Email address is required. Please enter a valid email.${NC}"
            fi
        done
    else
        echo -e "${BLUE}Using email from log monitoring: ${ADMIN_EMAIL}${NC}"
    fi
    
    cat > /usr/local/bin/security-check.sh << 'EOF'
#!/bin/bash
# Daily security check script

echo "=== Proxmox Security Check - $(date) ==="
echo

# Check fail2ban status
echo "Fail2Ban Status:"
echo "─────────────────────────────────────────"
if command -v fail2ban-client >/dev/null 2>&1; then
    fail2ban-client status 2>/dev/null || echo "Fail2Ban not running"
    echo
    # Show banned IPs
    for jail in $(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2 | tr ',' ' '); do
        banned=$(fail2ban-client status $jail 2>/dev/null | grep "Currently banned" | awk '{print $NF}')
        if [ "$banned" != "0" ]; then
            echo "⚠️  Jail $jail: $banned banned IP(s)"
        fi
    done
else
    echo "Fail2Ban not installed"
fi
echo

# Check for unusual network connections to management ports
echo "Management Port Status:"
echo "─────────────────────────────────────────"
# Check SSH (should be filtered from public)
ssh_public=$(netstat -tuln | grep ':22 ' | grep '0.0.0.0' | wc -l)
if [ "$ssh_public" -gt 0 ]; then
    echo "⚠️  SSH is listening on 0.0.0.0:22 (PUBLIC - should be Tailscale only)"
else
    echo "✓ SSH properly restricted"
fi

# Check Proxmox GUI (should be filtered from public)
pve_public=$(netstat -tuln | grep ':8006' | grep '0.0.0.0' | wc -l)
if [ "$pve_public" -gt 0 ]; then
    echo "⚠️  Proxmox GUI on 0.0.0.0:8006 (verify firewall blocks public access)"
else
    echo "✓ Proxmox GUI properly configured"
fi

# List all management ports
echo
echo "Active management ports:"
netstat -tuln | grep -E ':22|:8006|:81' | sed 's/^/  /'
echo

# Check firewall status
echo "Firewall Status:"
echo "─────────────────────────────────────────"
if command -v pve-firewall >/dev/null 2>&1; then
    pve_status=$(pve-firewall status 2>&1)
    if echo "$pve_status" | grep -q "enabled/running"; then
        echo "✓ Proxmox Firewall: enabled and running"
    else
        echo "⚠️  Proxmox Firewall status: $(echo "$pve_status" | head -1)"
    fi
    
    # Check for firewall errors and offer to fix them
    if echo "$pve_status" | grep -q "errors in rule"; then
        echo "⚠️  Firewall configuration errors detected!"
        echo
        
        # Check each container firewall config
        for fw_file in /etc/pve/firewall/*.fw; do
            if [ -f "$fw_file" ]; then
                # Check for rules missing -proto
                if grep -q "dport.*ACCEPT\|ACCEPT.*dport" "$fw_file" 2>/dev/null; then
                    if ! grep -q "proto tcp\|proto udp" "$fw_file" 2>/dev/null; then
                        echo "  Found fixable rules in: $fw_file"
                        echo "  Missing -proto specification for port rules"
                        
                        # Auto-fix: add -proto tcp to rules with -dport but no -proto
                        if grep -E "^(IN|OUT) (ACCEPT|DROP|REJECT).*-dport [0-9,]+\s*$" "$fw_file" >/dev/null 2>&1; then
                            echo "  Fixing: Adding -proto tcp to port-based rules..."
                            sed -i.bak 's/\(^[[:space:]]*\(IN\|OUT\)[[:space:]]\+\(ACCEPT\|DROP\|REJECT\).*-dport[[:space:]]\+[0-9,]\+\)\s*$/\1 -proto tcp/' "$fw_file"
                            echo "  ✓ Fixed rules in $fw_file (backup: ${fw_file}.bak)"
                        fi
                    fi
                fi
            fi
        done
        
        # Recompile firewall after fixes
        echo
        echo "Recompiling firewall configuration..."
        pve-firewall compile 2>&1 | grep -v "^$"
    fi
else
    echo "⚠️  pve-firewall not available"
fi
echo

# Check for failed authentication attempts (using journalctl for systemd)
echo "Recent Failed Authentication Attempts:"
echo "─────────────────────────────────────────"
if command -v journalctl >/dev/null 2>&1; then
    failed_auth=$(journalctl -u ssh.service --since "24 hours ago" 2>/dev/null | grep -i "failed\|failure" | wc -l)
    if [ "$failed_auth" -gt 0 ]; then
        echo "⚠️  $failed_auth failed SSH authentication attempts in last 24 hours"
        journalctl -u ssh.service --since "24 hours ago" 2>/dev/null | grep -i "failed\|failure" | tail -5 | sed 's/^/  /'
    else
        echo "✓ No failed authentication attempts in last 24 hours"
    fi
else
    # Fallback to auth.log if available
    if [ -f /var/log/auth.log ]; then
        failed_auth=$(tail -100 /var/log/auth.log | grep -i "authentication failure" | wc -l)
        if [ "$failed_auth" -gt 0 ]; then
            echo "⚠️  $failed_auth recent authentication failures"
            tail -20 /var/log/auth.log | grep "authentication failure" | tail -5 | sed 's/^/  /'
        else
            echo "✓ No authentication failures"
        fi
    else
        echo "ℹ️  Unable to check authentication logs"
    fi
fi
echo

# Check container status
echo "Container Status:"
echo "─────────────────────────────────────────"
if command -v pct >/dev/null 2>&1; then
    containers=$(pct list 2>/dev/null | tail -n +2)
    if [ -n "$containers" ]; then
        echo "$containers" | while read line; do
            ctid=$(echo "$line" | awk '{print $1}')
            status=$(echo "$line" | awk '{print $2}')
            name=$(echo "$line" | awk '{print $3}')
            if [ "$status" = "running" ]; then
                echo "  ✓ $ctid ($name): running"
            else
                echo "  ⚠️  $ctid ($name): $status"
            fi
        done
    else
        echo "  No containers found"
    fi
else
    echo "  Unable to check containers (pct not available)"
fi
echo

# Check system updates
echo "System Updates:"
echo "─────────────────────────────────────────"
if command -v apt >/dev/null 2>&1; then
    updates=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo 0)
    security=$(apt list --upgradable 2>/dev/null | grep -c "security" || echo 0)
    
    if [ "$updates" -eq 0 ]; then
        echo "✓ System is up to date"
    else
        echo "ℹ️  $updates package(s) available for update"
        if [ "$security" -gt 0 ]; then
            echo "⚠️  $security security update(s) available - APPLY SOON!"
        fi
    fi
else
    echo "  Unable to check updates"
fi
echo

# System resource check
echo "System Resources:"
echo "─────────────────────────────────────────"
# Disk usage
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$disk_usage" -gt 90 ]; then
    echo "⚠️  Disk usage: ${disk_usage}% (HIGH!)"
elif [ "$disk_usage" -gt 80 ]; then
    echo "⚠️  Disk usage: ${disk_usage}%"
else
    echo "✓ Disk usage: ${disk_usage}%"
fi

# Memory usage
if command -v free >/dev/null 2>&1; then
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100}')
    if [ "$mem_usage" -gt 90 ]; then
        echo "⚠️  Memory usage: ${mem_usage}% (HIGH!)"
    else
        echo "✓ Memory usage: ${mem_usage}%"
    fi
fi

echo
echo "=== End of Security Check ==="
EOF

    chmod +x /usr/local/bin/security-check.sh
    
    # Add to daily cron with user-provided email
    (crontab -l 2>/dev/null; echo "0 6 * * * /usr/local/bin/security-check.sh | mail -s 'Proxmox Security Report' ${ADMIN_EMAIL}") | crontab -
    
    echo -e "${GREEN}✓ Security check script created${NC}"
    echo -e "${BLUE}  Daily reports will be sent to: ${ADMIN_EMAIL}${NC}"
}

# Show interactive menu
show_menu() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Proxmox Security Hardening - v1.0.0                ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}What would you like to configure?${NC}"
    echo
    echo -e "  ${YELLOW}1)${NC} 🔒 Install and configure Fail2Ban"
    echo -e "  ${YELLOW}2)${NC} 🛡️  Configure container-level firewalls"
    echo -e "  ${YELLOW}3)${NC} 📊 Setup network monitoring"
    echo -e "  ${YELLOW}4)${NC} 💾 Configure backup security"
    echo -e "  ${YELLOW}5)${NC} 🔐 Harden SSH configuration"
    echo -e "  ${YELLOW}6)${NC} 📧 Setup log monitoring"
    echo -e "  ${YELLOW}7)${NC} 🔍 Create security check script"
    echo -e "  ${YELLOW}8)${NC} ⚡ Apply all configurations"
    echo -e "  ${YELLOW}0)${NC} ❌ Exit"
    echo
}

# Main menu
main_menu() {
    while true; do
        show_menu
        read -p "Enter your choice [0-8]: " choice
        echo
        
        case $choice in
            1)
                echo -e "${BLUE}🔒 Installing and configuring Fail2Ban...${NC}"
                echo
                install_fail2ban
                echo
                read -p "Press Enter to continue..."
                ;;
            2)
                echo -e "${BLUE}🛡️  Configuring container-level firewalls...${NC}"
                echo
                configure_container_firewall
                echo
                read -p "Press Enter to continue..."
                ;;
            3)
                echo -e "${BLUE}📊 Setting up network monitoring...${NC}"
                echo
                setup_monitoring
                echo
                read -p "Press Enter to continue..."
                ;;
            4)
                echo -e "${BLUE}💾 Configuring backup security...${NC}"
                echo
                setup_backup_security
                echo
                read -p "Press Enter to continue..."
                ;;
            5)
                echo -e "${BLUE}🔐 Hardening SSH configuration...${NC}"
                echo
                harden_ssh
                echo
                read -p "Press Enter to continue..."
                ;;
            6)
                echo -e "${BLUE}📧 Setting up log monitoring...${NC}"
                echo
                setup_log_monitoring
                echo
                read -p "Press Enter to continue..."
                ;;
            7)
                echo -e "${BLUE}🔍 Creating security check script...${NC}"
                echo
                create_security_checker
                echo
                read -p "Press Enter to continue..."
                ;;
            8)
                echo -e "${YELLOW}⚡ Applying all security configurations...${NC}"
                echo
                read -p "This will configure all security features. Continue? (y/n): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    echo
                    echo -e "${BLUE}[1/7]${NC} Installing Fail2Ban..."
                    install_fail2ban
                    echo
                    echo -e "${BLUE}[2/7]${NC} Configuring container firewalls..."
                    configure_container_firewall
                    echo
                    echo -e "${BLUE}[3/7]${NC} Setting up network monitoring..."
                    setup_monitoring
                    echo
                    echo -e "${BLUE}[4/7]${NC} Configuring backup security..."
                    setup_backup_security
                    echo
                    echo -e "${BLUE}[5/7]${NC} Hardening SSH..."
                    harden_ssh
                    echo
                    echo -e "${BLUE}[6/7]${NC} Setting up log monitoring..."
                    setup_log_monitoring
                    echo
                    echo -e "${BLUE}[7/7]${NC} Creating security checker..."
                    create_security_checker
                    echo
                    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
                    echo -e "${GREEN}║     All Security Configurations Completed!              ║${NC}"
                    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
                else
                    echo "Cancelled."
                fi
                echo
                read -p "Press Enter to continue..."
                ;;
            0)
                echo -e "${GREEN}👋 Security hardening complete. Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid choice. Please select 0-8.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Run main menu
main_menu

echo
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Security Hardening Complete!                        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${GREEN}✅ Next steps:${NC}"
echo "  1. Test fail2ban: ${BLUE}fail2ban-client status${NC}"
echo "  2. Review firewall rules: ${BLUE}pve-firewall status${NC}"
echo "  3. Run security check: ${BLUE}/usr/local/bin/security-check.sh${NC}"
echo "  4. Monitor logs: ${BLUE}tail -f /var/log/fail2ban.log${NC}"
echo
echo -e "${YELLOW}⚠️  Remember to:${NC}"
echo "  • Change default backup user password"
echo "  • Test all services after applying changes"
echo "  • Keep Proxmox and containers updated"