#!/bin/bash

# Proxmox Security Monitor
# Real-time security monitoring and alerting for Proxmox infrastructure
# Usage: ./security-monitor.sh [start|stop|status|check]

# Configuration
SCRIPT_DIR="/usr/local/bin"
LOG_DIR="/var/log/proxmox-security"
PID_FILE="/var/run/proxmox-security-monitor.pid"
ALERT_EMAIL="admin@yourdomain.com"
TAILSCALE_RANGE="100.64.0.0/10"
PRIVATE_RANGE="10.10.0.0/24"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create log directory
mkdir -p "$LOG_DIR"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_DIR/security.log"
}

# Alert function
send_alert() {
    local severity="$1"
    local message="$2"
    local subject="PROXMOX SECURITY ALERT [$severity]"
    
    log_message "ALERT" "$message"
    
    # Send email if mail is configured
    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "$subject" "$ALERT_EMAIL"
    fi
    
    # Log to syslog
    logger -p auth.warning "Proxmox Security Alert: $message"
}

# Check for suspicious network activity
check_network_activity() {
    # Monitor connections to management ports from non-Tailscale IPs
    netstat -tuln | grep -E ':22|:8006' | while read line; do
        if echo "$line" | grep -v "127.0.0.1\|$TAILSCALE_RANGE"; then
            send_alert "HIGH" "Management port exposed to public: $line"
        fi
    done
    
    # Check for high connection count to web services
    local web_connections=$(netstat -an | grep -E ':80|:443' | grep ESTABLISHED | wc -l)
    if [ "$web_connections" -gt 100 ]; then
        send_alert "MEDIUM" "High number of web connections detected: $web_connections"
    fi
}

# Check authentication logs
check_auth_logs() {
    # Check for failed SSH attempts (last 5 minutes)
    local failed_ssh=$(grep "$(date --date='5 minutes ago' '+%b %d %H:%M')" /var/log/auth.log | grep "authentication failure" | wc -l)
    if [ "$failed_ssh" -gt 5 ]; then
        send_alert "HIGH" "Multiple SSH authentication failures detected: $failed_ssh attempts"
    fi
    
    # Check for Proxmox authentication failures
    local failed_proxmox=$(grep "$(date --date='5 minutes ago' '+%b %d %H:%M')" /var/log/daemon.log | grep "pvedaemon.*authentication failure" | wc -l)
    if [ "$failed_proxmox" -gt 3 ]; then
        send_alert "HIGH" "Multiple Proxmox authentication failures detected: $failed_proxmox attempts"
    fi
}

# Check system integrity
check_system_integrity() {
    # Check if critical services are running
    local services=("pvedaemon" "pveproxy" "pve-firewall" "fail2ban")
    
    for service in "${services[@]}"; do
        if ! systemctl is-active --quiet "$service"; then
            send_alert "CRITICAL" "Critical service not running: $service"
        fi
    done
    
    # Check container status
    local stopped_containers=$(pct list | grep stopped | wc -l)
    if [ "$stopped_containers" -gt 0 ]; then
        local container_list=$(pct list | grep stopped | awk '{print $1}')
        send_alert "MEDIUM" "Containers stopped unexpectedly: $container_list"
    fi
}

# Check firewall rules
check_firewall_rules() {
    # Verify Proxmox firewall is enabled
    if ! pve-firewall status | grep -q "Status: enabled"; then
        send_alert "CRITICAL" "Proxmox firewall is disabled!"
    fi
    
    # Check if management ports are blocked from public
    local iptables_rules=$(iptables -L INPUT -n | grep -E "22|8006")
    if [ -z "$iptables_rules" ]; then
        send_alert "HIGH" "No iptables rules found for management ports"
    fi
}

# Check for unusual processes
check_processes() {
    # Look for suspicious network processes
    local suspicious_processes=$(ps aux | grep -E "nc|netcat|nmap|masscan|nikto" | grep -v grep)
    if [ -n "$suspicious_processes" ]; then
        send_alert "HIGH" "Suspicious network processes detected: $suspicious_processes"
    fi
    
    # Check for high CPU usage processes
    local high_cpu=$(ps aux --sort=-%cpu | head -5 | awk '$3 > 80.0 {print $11 " (" $3 "%)"}'
    if [ -n "$high_cpu" ]; then
        send_alert "MEDIUM" "High CPU usage detected: $high_cpu"
    fi
}

# Check disk usage and logs
check_disk_usage() {
    # Check for full disks
    df -h | awk '$5 > 90 {print $6 " is " $5 " full"}' | while read line; do
        if [ -n "$line" ]; then
            send_alert "HIGH" "Disk space critical: $line"
        fi
    done
    
    # Check log file sizes
    find /var/log -name "*.log" -size +100M | while read logfile; do
        send_alert "MEDIUM" "Large log file detected: $logfile ($(du -h "$logfile" | cut -f1))"
    done
}

# Real-time monitoring function
start_monitoring() {
    log_message "INFO" "Starting Proxmox security monitoring"
    
    while true; do
        check_network_activity
        check_auth_logs
        check_system_integrity
        check_firewall_rules
        check_processes
        check_disk_usage
        
        sleep 60  # Check every minute
    done
}

# Generate security report
generate_report() {
    local report_file="$LOG_DIR/security-report-$(date +%Y%m%d-%H%M%S).txt"
    
    echo "=== Proxmox Security Report - $(date) ===" > "$report_file"
    echo >> "$report_file"
    
    echo "System Status:" >> "$report_file"
    systemctl status pvedaemon pveproxy pve-firewall fail2ban --no-pager >> "$report_file" 2>&1
    echo >> "$report_file"
    
    echo "Container Status:" >> "$report_file"
    pct list >> "$report_file"
    echo >> "$report_file"
    
    echo "Network Connections:" >> "$report_file"
    netstat -tuln | grep -E ':22|:80|:443|:8006|:81' >> "$report_file"
    echo >> "$report_file"
    
    echo "Firewall Status:" >> "$report_file"
    pve-firewall status >> "$report_file"
    echo >> "$report_file"
    
    echo "Recent Authentication Failures:" >> "$report_file"
    grep "authentication failure" /var/log/auth.log | tail -10 >> "$report_file"
    echo >> "$report_file"
    
    echo "Fail2Ban Status:" >> "$report_file"
    fail2ban-client status >> "$report_file" 2>&1
    echo >> "$report_file"
    
    echo "Disk Usage:" >> "$report_file"
    df -h >> "$report_file"
    echo >> "$report_file"
    
    echo "Memory Usage:" >> "$report_file"
    free -h >> "$report_file"
    echo >> "$report_file"
    
    echo "Top Processes:" >> "$report_file"
    ps aux --sort=-%cpu | head -10 >> "$report_file"
    
    log_message "INFO" "Security report generated: $report_file"
    echo "$report_file"
}

# Main script logic
case "$1" in
    start)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo -e "${YELLOW}Security monitor is already running${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}Starting Proxmox security monitor...${NC}"
        nohup bash -c "$(declare -f start_monitoring check_network_activity check_auth_logs check_system_integrity check_firewall_rules check_processes check_disk_usage log_message send_alert); start_monitoring" > "$LOG_DIR/monitor.log" 2>&1 &
        echo $! > "$PID_FILE"
        echo -e "${GREEN}✓ Security monitor started (PID: $!)${NC}"
        ;;
        
    stop)
        if [ -f "$PID_FILE" ]; then
            local pid=$(cat "$PID_FILE")
            if kill "$pid" 2>/dev/null; then
                rm -f "$PID_FILE"
                echo -e "${GREEN}✓ Security monitor stopped${NC}"
            else
                echo -e "${RED}Failed to stop security monitor${NC}"
                rm -f "$PID_FILE"
            fi
        else
            echo -e "${YELLOW}Security monitor is not running${NC}"
        fi
        ;;
        
    status)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo -e "${GREEN}Security monitor is running (PID: $(cat "$PID_FILE"))${NC}"
            echo "Log file: $LOG_DIR/security.log"
            echo "Monitor log: $LOG_DIR/monitor.log"
        else
            echo -e "${RED}Security monitor is not running${NC}"
        fi
        ;;
        
    check)
        echo -e "${BLUE}Running security check...${NC}"
        check_network_activity
        check_auth_logs
        check_system_integrity
        check_firewall_rules
        check_processes
        check_disk_usage
        echo -e "${GREEN}✓ Security check completed${NC}"
        ;;
        
    report)
        echo -e "${BLUE}Generating security report...${NC}"
        report_file=$(generate_report)
        echo -e "${GREEN}✓ Report saved to: $report_file${NC}"
        ;;
        
    install)
        echo -e "${BLUE}Installing security monitor as system service...${NC}"
        
        # Copy script to system location
        cp "$0" "$SCRIPT_DIR/proxmox-security-monitor"
        chmod +x "$SCRIPT_DIR/proxmox-security-monitor"
        
        # Create systemd service
        cat > /etc/systemd/system/proxmox-security-monitor.service << EOF
[Unit]
Description=Proxmox Security Monitor
After=network.target

[Service]
Type=forking
ExecStart=$SCRIPT_DIR/proxmox-security-monitor start
ExecStop=$SCRIPT_DIR/proxmox-security-monitor stop
PIDFile=$PID_FILE
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable proxmox-security-monitor
        echo -e "${GREEN}✓ Security monitor installed as system service${NC}"
        echo "Start with: systemctl start proxmox-security-monitor"
        ;;
        
    *)
        echo "Usage: $0 {start|stop|status|check|report|install}"
        echo
        echo "Commands:"
        echo "  start   - Start real-time security monitoring"
        echo "  stop    - Stop security monitoring"
        echo "  status  - Check monitor status"
        echo "  check   - Run one-time security check"
        echo "  report  - Generate comprehensive security report"
        echo "  install - Install as system service"
        echo
        echo "Configuration:"
        echo "  Edit ALERT_EMAIL in script for email alerts"
        echo "  Logs stored in: $LOG_DIR"
        exit 1
        ;;
esac