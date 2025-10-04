#!/bin/bash

# Proxmox Security Updates Manager
# Automated security updates and maintenance for Proxmox infrastructure
# Usage: ./security-updates.sh [update|check|schedule|rollback]

# Configuration
LOG_FILE="/var/log/proxmox-updates.log"
BACKUP_DIR="/var/backups/proxmox-configs"
EMAIL="admin@yourdomain.com"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Backup critical configurations
backup_configs() {
    log_message "INFO" "Creating configuration backup"
    
    mkdir -p "$BACKUP_DIR/$(date +%Y%m%d-%H%M%S)"
    local backup_path="$BACKUP_DIR/$(date +%Y%m%d-%H%M%S)"
    
    # Backup Proxmox configurations
    cp -r /etc/pve "$backup_path/"
    cp /etc/network/interfaces "$backup_path/"
    cp /etc/hosts "$backup_path/"
    cp /etc/resolv.conf "$backup_path/"
    
    # Backup security configurations
    cp -r /etc/fail2ban "$backup_path/" 2>/dev/null || true
    cp /etc/ssh/sshd_config "$backup_path/"
    
    # Backup iptables rules
    iptables-save > "$backup_path/iptables.rules"
    
    # Create backup manifest
    cat > "$backup_path/MANIFEST" << EOF
Backup created: $(date)
Proxmox version: $(pveversion)
Kernel version: $(uname -r)
Packages before update: $(dpkg -l | wc -l)
EOF

    log_message "INFO" "Configuration backup saved to $backup_path"
    echo "$backup_path"
}

# Check for available updates
check_updates() {
    log_message "INFO" "Checking for available updates"
    
    # Update package lists
    apt update >/dev/null 2>&1
    
    # Check for Proxmox updates
    local pve_updates=$(apt list --upgradable 2>/dev/null | grep -c "pve-")
    local security_updates=$(apt list --upgradable 2>/dev/null | grep -c "security")
    local total_updates=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")
    
    echo -e "${BLUE}Update Summary:${NC}"
    echo "• Total packages: $total_updates"
    echo "• Security updates: $security_updates"
    echo "• Proxmox VE updates: $pve_updates"
    echo
    
    if [ "$total_updates" -gt 0 ]; then
        echo -e "${YELLOW}Available updates:${NC}"
        apt list --upgradable 2>/dev/null | grep -v "WARNING"
        echo
    fi
    
    # Check container updates
    echo -e "${BLUE}Container Update Status:${NC}"
    pct list | tail -n +2 | while read line; do
        local ctid=$(echo "$line" | awk '{print $1}')
        local status=$(echo "$line" | awk '{print $2}')
        local name=$(echo "$line" | awk '{print $3}')
        
        if [ "$status" = "running" ]; then
            echo "Container $ctid ($name): $status"
            # Check if container needs updates (this is a simplified check)
            pct exec "$ctid" -- bash -c "apt list --upgradable 2>/dev/null | wc -l" 2>/dev/null || echo "  Unable to check updates"
        fi
    done
}

# Apply security updates
apply_updates() {
    local update_type="$1"  # security, all, or proxmox
    
    log_message "INFO" "Starting $update_type updates"
    
    # Create backup first
    local backup_path=$(backup_configs)
    
    # Pre-update checks
    log_message "INFO" "Running pre-update checks"
    
    # Check disk space
    local root_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$root_usage" -gt 90 ]; then
        log_message "ERROR" "Insufficient disk space for updates (${root_usage}% used)"
        return 1
    fi
    
    # Check if critical services are running
    local critical_services=("pvedaemon" "pveproxy" "pve-firewall")
    for service in "${critical_services[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            log_message "WARNING" "Critical service $service is not running"
        fi
    done
    
    # Apply updates based on type
    case "$update_type" in
        security)
            log_message "INFO" "Applying security updates only"
            apt update
            apt upgrade -y $(apt list --upgradable 2>/dev/null | grep security | awk -F/ '{print $1}')
            ;;
        proxmox)
            log_message "INFO" "Applying Proxmox VE updates"
            apt update
            apt upgrade -y $(apt list --upgradable 2>/dev/null | grep pve- | awk -F/ '{print $1}')
            ;;
        all)
            log_message "INFO" "Applying all available updates"
            apt update
            apt upgrade -y
            ;;
        *)
            log_message "ERROR" "Invalid update type: $update_type"
            return 1
            ;;
    esac
    
    # Post-update checks
    log_message "INFO" "Running post-update checks"
    
    # Check if reboot is required
    if [ -f /var/run/reboot-required ]; then
        log_message "WARNING" "System reboot required after updates"
        echo -e "${YELLOW}⚠ System reboot required${NC}"
        
        if command -v mail >/dev/null 2>&1; then
            echo "Proxmox system requires reboot after security updates" | mail -s "Proxmox Reboot Required" "$EMAIL"
        fi
    fi
    
    # Verify critical services
    for service in "${critical_services[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            log_message "ERROR" "Critical service $service failed after update"
            systemctl restart "$service"
        fi
    done
    
    # Test network connectivity
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_message "ERROR" "Network connectivity lost after update"
    fi
    
    # Update security tools
    if command -v fail2ban-client >/dev/null 2>&1; then
        systemctl restart fail2ban
        log_message "INFO" "Fail2ban restarted"
    fi
    
    log_message "INFO" "Updates completed successfully"
    echo -e "${GREEN}✓ Updates applied successfully${NC}"
    echo "Backup saved to: $backup_path"
}

# Update containers
update_containers() {
    log_message "INFO" "Updating containers"
    
    pct list | tail -n +2 | while read line; do
        local ctid=$(echo "$line" | awk '{print $1}')
        local status=$(echo "$line" | awk '{print $2}')
        local name=$(echo "$line" | awk '{print $3}')
        
        if [ "$status" = "running" ]; then
            echo -e "${BLUE}Updating container $ctid ($name)...${NC}"
            
            # Create container snapshot before update
            pct snapshot "$ctid" "pre-update-$(date +%Y%m%d-%H%M%S)" --description "Before security updates"
            
            # Update container
            pct exec "$ctid" -- bash -c "
                apt update
                apt upgrade -y
                apt autoremove -y
                apt autoclean
            " 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Container $ctid updated successfully${NC}"
                log_message "INFO" "Container $ctid updated successfully"
            else
                echo -e "${RED}✗ Failed to update container $ctid${NC}"
                log_message "ERROR" "Failed to update container $ctid"
            fi
        else
            echo -e "${YELLOW}⚠ Container $ctid is $status, skipping${NC}"
        fi
    done
}

# Schedule automatic updates
schedule_updates() {
    log_message "INFO" "Configuring automatic security updates"
    
    # Install unattended-upgrades if not present
    if ! dpkg -l | grep -q unattended-upgrades; then
        apt update && apt install -y unattended-upgrades
    fi
    
    # Configure unattended-upgrades for security updates only
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "Proxmox:${distro_codename}";
};

Unattended-Upgrade::Package-Blacklist {
    "pve-kernel-*";
    "proxmox-ve";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "admin@yourdomain.com";
EOF

    # Configure automatic updates schedule
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

    # Add custom update script to cron
    cat > /etc/cron.d/proxmox-security-updates << EOF
# Proxmox Security Updates
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Weekly security updates (Sundays at 2 AM)
0 2 * * 0 root $(realpath "$0") update security >/dev/null 2>&1

# Monthly full system check (1st day of month at 3 AM)
0 3 1 * * root $(realpath "$0") check

# Daily container updates check (weekdays at 1 AM)
0 1 * * 1-5 root $(realpath "$0") check-containers
EOF

    systemctl enable unattended-upgrades
    systemctl start unattended-upgrades
    
    log_message "INFO" "Automatic security updates configured"
    echo -e "${GREEN}✓ Automatic security updates configured${NC}"
    echo "• Security updates: Weekly (Sundays 2 AM)"
    echo "• System checks: Monthly (1st day 3 AM)"  
    echo "• Container checks: Daily (weekdays 1 AM)"
}

# Rollback to previous configuration
rollback_config() {
    echo -e "${YELLOW}Available configuration backups:${NC}"
    ls -la "$BACKUP_DIR" | grep "^d" | awk '{print $9}' | grep -E "^[0-9]" | sort -r | head -10
    echo
    
    read -p "Enter backup directory name to restore: " backup_name
    
    if [ ! -d "$BACKUP_DIR/$backup_name" ]; then
        echo -e "${RED}Backup directory not found${NC}"
        return 1
    fi
    
    echo -e "${RED}WARNING: This will restore system configuration to $backup_name${NC}"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "Rollback cancelled"
        return 0
    fi
    
    log_message "WARNING" "Starting configuration rollback to $backup_name"
    
    # Stop services
    systemctl stop pveproxy pvedaemon
    
    # Restore configurations
    cp -r "$BACKUP_DIR/$backup_name/pve"/* /etc/pve/
    cp "$BACKUP_DIR/$backup_name/interfaces" /etc/network/
    cp "$BACKUP_DIR/$backup_name/sshd_config" /etc/ssh/
    
    # Restore iptables rules
    if [ -f "$BACKUP_DIR/$backup_name/iptables.rules" ]; then
        iptables-restore < "$BACKUP_DIR/$backup_name/iptables.rules"
    fi
    
    # Restart services
    systemctl start pvedaemon pveproxy
    systemctl restart networking
    
    log_message "INFO" "Configuration rollback completed"
    echo -e "${GREEN}✓ Configuration restored from $backup_name${NC}"
}

# Main script logic
case "$1" in
    check)
        check_updates
        ;;
    
    update)
        if [ -z "$2" ]; then
            echo "Usage: $0 update {security|proxmox|all}"
            exit 1
        fi
        apply_updates "$2"
        ;;
    
    containers)
        update_containers
        ;;
    
    schedule)
        schedule_updates
        ;;
    
    rollback)
        rollback_config
        ;;
    
    backup)
        backup_path=$(backup_configs)
        echo -e "${GREEN}✓ Configuration backup created: $backup_path${NC}"
        ;;
    
    *)
        echo "Proxmox Security Updates Manager"
        echo
        echo "Usage: $0 {check|update|containers|schedule|rollback|backup}"
        echo
        echo "Commands:"
        echo "  check              - Check for available updates"
        echo "  update <type>      - Apply updates (security|proxmox|all)"
        echo "  containers         - Update all running containers"
        echo "  schedule           - Configure automatic security updates"
        echo "  rollback           - Restore previous configuration"
        echo "  backup             - Create configuration backup"
        echo
        echo "Examples:"
        echo "  $0 check"
        echo "  $0 update security"
        echo "  $0 containers"
        echo "  $0 schedule"
        exit 1
        ;;
esac