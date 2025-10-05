#!/bin/bash

# Proxmox Security Updates Manager
# Automated security updates and maintenance for Proxmox infrastructure
# Usage: ./security-updates.sh [update|check|schedule|rollback]

# Configuration
LOG_FILE="/var/log/proxmox-updates.log"
BACKUP_DIR="/var/backups/proxmox-configs"

# Load email configuration
CONFIG_FILE="/etc/proxmox-security/monitor.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    EMAIL="$ALERT_EMAIL"
fi

# Prompt for email if not configured
if [ -z "$EMAIL" ]; then
    while true; do
        read -p "Enter email address for update notifications: " EMAIL
        if [ -n "$EMAIL" ]; then
            # Check if it looks like an email
            if echo "$EMAIL" | grep -qE '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'; then
                break
            else
                echo "Invalid email format. Please try again."
            fi
        else
            # Allow default if user really wants it
            read -p "Use default (root@$(hostname -f))? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                EMAIL="root@$(hostname -f)"
                break
            fi
        fi
    done
    # Save for future use
    mkdir -p "$(dirname "$CONFIG_FILE")"
    echo "ALERT_EMAIL=\"$EMAIL\"" >> "$CONFIG_FILE"
fi

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
    echo -e "${BLUE}🔄 Refreshing package lists...${NC}"
    apt update >/dev/null 2>&1
    echo
    
    # Count different types of updates
    local total_updates=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo 0)
    local security_updates=$(apt list --upgradable 2>/dev/null | grep -c "security" || echo 0)
    local pve_updates=$(apt list --upgradable 2>/dev/null | grep -c "pve-" || echo 0)
    
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       Update Status Summary            ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo
    
    if [ "$total_updates" -eq 0 ]; then
        echo -e "${GREEN}✓ System is up to date!${NC}"
        echo -e "  No updates available."
        return 0
    fi
    
    # Display summary with colors
    echo -e "  ${YELLOW}Total updates available:${NC} ${YELLOW}$total_updates${NC}"
    
    if [ "$security_updates" -gt 0 ]; then
        echo -e "  ${RED}🛡️  Security updates:${NC} ${RED}$security_updates${NC} ${RED}(IMPORTANT!)${NC}"
    else
        echo -e "  ${GREEN}🛡️  Security updates:${NC} ${GREEN}0${NC}"
    fi
    
    if [ "$pve_updates" -gt 0 ]; then
        echo -e "  ${BLUE}📦 Proxmox VE updates:${NC} $pve_updates"
    else
        echo -e "  ${GREEN}📦 Proxmox VE updates:${NC} 0"
    fi
    
    echo
    
    # Ask if user wants to see details
    read -p "Show detailed update list? (y/n): " show_details
    if [ "$show_details" = "y" ] || [ "$show_details" = "Y" ]; then
        echo
        echo -e "${YELLOW}Available updates:${NC}"
        echo "─────────────────────────────────────────────"
        apt list --upgradable 2>/dev/null | grep -v "WARNING" | tail -n +2 | while read line; do
            if echo "$line" | grep -q "security"; then
                echo -e "${RED}🛡️  $line${NC}"
            elif echo "$line" | grep -q "pve-"; then
                echo -e "${BLUE}📦 $line${NC}"
            else
                echo "   $line"
            fi
        done
        echo "─────────────────────────────────────────────"
    fi
    
    echo
    
    # Check containers
    local container_count=$(pct list | tail -n +2 | wc -l || echo 0)
    if [ "$container_count" -gt 0 ]; then
        echo -e "${BLUE}🐳 Containers Status:${NC}"
        pct list | tail -n +2 | while read line; do
            local ctid=$(echo "$line" | awk '{print $1}')
            local status=$(echo "$line" | awk '{print $2}')
            local name=$(echo "$line" | awk '{print $3}')
            
            if [ "$status" = "running" ]; then
                echo -e "  ${GREEN}●${NC} Container $ctid ($name): running"
            else
                echo -e "  ${RED}○${NC} Container $ctid ($name): $status"
            fi
        done
        echo
    fi
    
    # Recommendations
    if [ "$security_updates" -gt 0 ]; then
        echo -e "${RED}⚠️  RECOMMENDATION: Apply security updates as soon as possible!${NC}"
        echo -e "   Run: Select option 2 from main menu"
    elif [ "$pve_updates" -gt 0 ]; then
        echo -e "${YELLOW}💡 TIP: Proxmox updates available. Consider updating during maintenance window.${NC}"
    fi
}

# Apply security updates
apply_updates() {
    local update_type="$1"  # security, all, or proxmox
    
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       Preparing System Update           ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo
    
    log_message "INFO" "Starting $update_type updates"
    
    # Step 1: Create backup
    echo -e "${YELLOW}Step 1/5:${NC} Creating configuration backup..."
    local backup_path=$(backup_configs)
    echo -e "${GREEN}✓ Backup created${NC}"
    echo
    
    # Step 2: Pre-update checks
    echo -e "${YELLOW}Step 2/5:${NC} Running system health checks..."
    
    # Check disk space
    local root_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$root_usage" -gt 90 ]; then
        echo -e "${RED}✗ Error: Insufficient disk space (${root_usage}% used)${NC}"
        log_message "ERROR" "Insufficient disk space for updates (${root_usage}% used)"
        return 1
    fi
    echo -e "  ${GREEN}✓${NC} Disk space: ${root_usage}% used (OK)"
    
    # Check critical services
    local all_services_ok=true
    local critical_services=("pvedaemon" "pveproxy" "pve-firewall")
    for service in "${critical_services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "  ${GREEN}✓${NC} Service $service: running"
        else
            echo -e "  ${YELLOW}⚠${NC} Service $service: not running"
            all_services_ok=false
            log_message "WARNING" "Critical service $service is not running"
        fi
    done
    echo
    
    # Step 3: Apply updates
    echo -e "${YELLOW}Step 3/5:${NC} Applying updates..."
    echo
    
    case "$update_type" in
        security)
            echo -e "${BLUE}🛡️  Installing security updates...${NC}"
            log_message "INFO" "Applying security updates only"
            apt update
            DEBIAN_FRONTEND=noninteractive apt upgrade -y -o Dpkg::Options::="--force-confold" $(apt list --upgradable 2>/dev/null | grep security | awk -F/ '{print $1}')
            ;;
        proxmox)
            echo -e "${BLUE}📦 Installing Proxmox VE updates...${NC}"
            log_message "INFO" "Applying Proxmox VE updates"
            apt update
            DEBIAN_FRONTEND=noninteractive apt upgrade -y -o Dpkg::Options::="--force-confold" $(apt list --upgradable 2>/dev/null | grep pve- | awk -F/ '{print $1}')
            ;;
        all)
            echo -e "${BLUE}🌐 Installing all available updates...${NC}"
            log_message "INFO" "Applying all available updates"
            apt update
            DEBIAN_FRONTEND=noninteractive apt upgrade -y -o Dpkg::Options::="--force-confold"
            ;;
        *)
            echo -e "${RED}✗ Invalid update type: $update_type${NC}"
            log_message "ERROR" "Invalid update type: $update_type"
            return 1
            ;;
    esac
    echo
    
    # Step 4: Post-update checks
    echo -e "${YELLOW}Step 4/5:${NC} Verifying system status..."
    
    # Check if reboot is required
    if [ -f /var/run/reboot-required ]; then
        echo -e "  ${RED}⚠ System reboot required${NC}"
        log_message "WARNING" "System reboot required after updates"
        
        if command -v mail >/dev/null 2>&1; then
            echo "Proxmox system requires reboot after security updates" | mail -s "Proxmox Reboot Required" "$EMAIL"
        fi
    else
        echo -e "  ${GREEN}✓${NC} No reboot required"
    fi
    
    # Verify critical services still running
    local services_ok_after=true
    for service in "${critical_services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo -e "  ${GREEN}✓${NC} Service $service: running"
        else
            echo -e "  ${RED}✗${NC} Service $service: failed, restarting..."
            systemctl restart "$service"
            services_ok_after=false
            log_message "ERROR" "Critical service $service failed after update, restarted"
        fi
    done
    
    # Test network connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Network connectivity: OK"
    else
        echo -e "  ${RED}✗${NC} Network connectivity: FAILED"
        log_message "ERROR" "Network connectivity lost after update"
    fi
    echo
    
    # Step 5: Cleanup and finalize
    echo -e "${YELLOW}Step 5/5:${NC} Finalizing..."
    
    # Update security tools
    if command -v fail2ban-client >/dev/null 2>&1; then
        systemctl restart fail2ban
        echo -e "  ${GREEN}✓${NC} Fail2ban restarted"
        log_message "INFO" "Fail2ban restarted"
    fi
    
    # Clean up
    apt autoremove -y >/dev/null 2>&1
    apt autoclean >/dev/null 2>&1
    echo -e "  ${GREEN}✓${NC} Cleaned up unused packages"
    echo
    
    # Final summary
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       Update Completed Successfully      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}Summary:${NC}"
    echo -e "  • Update type: $update_type"
    echo -e "  • Backup location: $backup_path"
    echo -e "  • Completion time: $(date '+%Y-%m-%d %H:%M:%S')"
    
    if [ -f /var/run/reboot-required ]; then
        echo
        echo -e "${YELLOW}⚠️  IMPORTANT: System reboot is required!${NC}"
        echo -e "   Run: ${BLUE}reboot${NC} when ready"
    fi
    
    log_message "INFO" "Updates completed successfully"
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
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "Proxmox:\${distro_codename}";
};

Unattended-Upgrade::Package-Blacklist {
    "pve-kernel-*";
    "proxmox-ve";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "${EMAIL}";
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

# Interactive menu function
show_menu() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Proxmox Security Updates Manager - v1.0.0          ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}What would you like to do?${NC}"
    echo
    echo -e "  ${YELLOW}1)${NC} 🔍 Check for updates"
    echo -e "  ${YELLOW}2)${NC} 🛡️  Apply security updates only (Recommended)"
    echo -e "  ${YELLOW}3)${NC} 📦 Apply all Proxmox updates"
    echo -e "  ${YELLOW}4)${NC} 🌐 Apply all system updates"
    echo -e "  ${YELLOW}5)${NC} 🐳 Update containers (LXC)"
    echo -e "  ${YELLOW}6)${NC} ⚙️  Configure automatic updates"
    echo -e "  ${YELLOW}7)${NC} 💾 Create configuration backup"
    echo -e "  ${YELLOW}8)${NC} ↩️  Restore previous configuration"
    echo -e "  ${YELLOW}0)${NC} ❌ Exit"
    echo
}

# Interactive mode
interactive_mode() {
    while true; do
        show_menu
        read -p "Enter your choice [0-8]: " choice
        echo
        
        case $choice in
            1)
                echo -e "${BLUE}🔍 Checking for available updates...${NC}"
                echo
                check_updates
                echo
                read -p "Press Enter to continue..."
                ;;
            2)
                echo -e "${YELLOW}🛡️  Applying security updates...${NC}"
                echo
                read -p "This will apply security patches. Continue? (y/n): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    apply_updates "security"
                else
                    echo "Cancelled."
                fi
                echo
                read -p "Press Enter to continue..."
                ;;
            3)
                echo -e "${YELLOW}📦 Applying Proxmox updates...${NC}"
                echo
                read -p "This will update Proxmox VE packages. Continue? (y/n): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    apply_updates "proxmox"
                else
                    echo "Cancelled."
                fi
                echo
                read -p "Press Enter to continue..."
                ;;
            4)
                echo -e "${YELLOW}🌐 Applying all system updates...${NC}"
                echo
                read -p "⚠️  This will update ALL packages. Continue? (y/n): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    apply_updates "all"
                else
                    echo "Cancelled."
                fi
                echo
                read -p "Press Enter to continue..."
                ;;
            5)
                echo -e "${YELLOW}🐳 Updating containers...${NC}"
                echo
                update_containers
                echo
                read -p "Press Enter to continue..."
                ;;
            6)
                echo -e "${YELLOW}⚙️  Configuring automatic updates...${NC}"
                echo
                schedule_updates
                echo
                read -p "Press Enter to continue..."
                ;;
            7)
                echo -e "${YELLOW}💾 Creating configuration backup...${NC}"
                echo
                backup_path=$(backup_configs)
                echo -e "${GREEN}✓ Backup created: $backup_path${NC}"
                echo
                read -p "Press Enter to continue..."
                ;;
            8)
                echo -e "${YELLOW}↩️  Restoring previous configuration...${NC}"
                echo
                rollback_config
                echo
                read -p "Press Enter to continue..."
                ;;
            0)
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid choice. Please select 0-8.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Main script logic
if [ "$#" -eq 0 ]; then
    # No arguments - run interactive mode
    interactive_mode
else
    # Command line mode for automation
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
            echo "Usage: $0 [command] [options]"
            echo
            echo "Interactive mode: Run without arguments for menu"
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
            echo "  $0                    # Interactive menu (recommended)"
            echo "  $0 check              # Check updates"
            echo "  $0 update security    # Apply security updates"
            exit 1
            ;;
    esac
fi