#!/bin/bash

# Proxmox Firewall Rules Fixer
# Automatically fixes common firewall rule syntax errors
# Usage: ./fix-firewall-rules.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Proxmox Firewall Rules Fixer          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    exit 1
fi

# Check if pve-firewall is available
if ! command -v pve-firewall >/dev/null 2>&1; then
    echo -e "${RED}Error: pve-firewall not found. Is this a Proxmox host?${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking firewall configuration...${NC}"
echo

# Get current firewall status
pve_status=$(pve-firewall status 2>&1)

if echo "$pve_status" | grep -q "errors in rule"; then
    echo -e "${RED}✗ Firewall configuration errors detected${NC}"
    echo
    
    fixed_count=0
    error_count=0
    
    # Process each firewall configuration file
    for fw_file in /etc/pve/firewall/*.fw; do
        if [ -f "$fw_file" ]; then
            container_id=$(basename "$fw_file" .fw)
            
            # Check if file has rules with -dport but missing -proto
            if grep -qE "^[[:space:]]*(IN|OUT)[[:space:]]+(ACCEPT|DROP|REJECT).*-dport.*" "$fw_file"; then
                # Check if any rules are missing -proto
                missing_proto=$(grep -E "^[[:space:]]*(IN|OUT)[[:space:]]+(ACCEPT|DROP|REJECT).*-dport[[:space:]]+[0-9,]+" "$fw_file" | grep -v "\-proto")
                
                if [ -n "$missing_proto" ]; then
                    echo -e "${YELLOW}Processing: $fw_file${NC}"
                    echo -e "  Found rules missing -proto specification:"
                    echo "$missing_proto" | sed 's/^/    /'
                    echo
                    
                    # Create backup
                    cp "$fw_file" "${fw_file}.backup-$(date +%Y%m%d-%H%M%S)"
                    echo -e "  ${GREEN}✓${NC} Backup created: ${fw_file}.backup-$(date +%Y%m%d-%H%M%S)"
                    
                    # Fix: Add -proto tcp to rules with -dport but no -proto
                    # Pattern: Lines ending with -dport NUMBERS (no -proto after)
                    sed -i 's/\(^[[:space:]]*\(IN\|OUT\)[[:space:]]\+\(ACCEPT\|DROP\|REJECT\)[^#]*-dport[[:space:]]\+[0-9,]\+\)[[:space:]]*$/\1 -proto tcp/' "$fw_file"
                    
                    echo -e "  ${GREEN}✓${NC} Added -proto tcp to port-based rules"
                    ((fixed_count++))
                    echo
                fi
            fi
            
            # Check for invalid IP addresses (like the 00001010... issue)
            if grep -qE "source [0-9]{8,}" "$fw_file"; then
                echo -e "${YELLOW}Warning: Container $container_id has invalid IP format${NC}"
                echo -e "  Please manually review: $fw_file"
                ((error_count++))
            fi
        fi
    done
    
    echo
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    
    if [ $fixed_count -gt 0 ]; then
        echo -e "${GREEN}✓ Fixed firewall rules in $fixed_count file(s)${NC}"
        echo
        
        # Recompile firewall
        echo -e "${YELLOW}Recompiling firewall configuration...${NC}"
        compile_output=$(pve-firewall compile 2>&1)
        
        if echo "$compile_output" | grep -q "error"; then
            echo -e "${RED}✗ Compilation errors still present:${NC}"
            echo "$compile_output"
            echo
            echo -e "${YELLOW}Manual intervention required. Check:${NC}"
            echo "  1. Invalid IP address formats"
            echo "  2. Duplicate rules"
            echo "  3. Invalid protocol specifications"
        else
            echo -e "${GREEN}✓ Firewall configuration compiled successfully${NC}"
            echo
            
            # Restart firewall to apply changes
            read -p "Restart firewall to apply changes? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                systemctl restart pve-firewall
                echo -e "${GREEN}✓ Firewall restarted${NC}"
            else
                echo -e "${YELLOW}Note: Changes will apply after firewall restart${NC}"
                echo "  Run: systemctl restart pve-firewall"
            fi
        fi
    else
        echo -e "${YELLOW}No automatic fixes applied${NC}"
    fi
    
    if [ $error_count -gt 0 ]; then
        echo
        echo -e "${YELLOW}⚠️  $error_count file(s) require manual review${NC}"
    fi
    
else
    echo -e "${GREEN}✓ No firewall configuration errors detected${NC}"
    echo
    pve-firewall status
fi

echo
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}Firewall Rules Best Practices:${NC}"
echo
echo "1. Always specify protocol for port rules:"
echo "   ✓ IN ACCEPT -source 10.0.0.0/8 -dport 80,443 -proto tcp"
echo "   ✗ IN ACCEPT -source 10.0.0.0/8 -dport 80,443"
echo
echo "2. Use -proto tcp for TCP ports (HTTP, SSH, etc.)"
echo "3. Use -proto udp for UDP ports (DNS, NTP, etc.)"
echo "4. Use -proto icmp for ICMP (ping)"
echo
echo "5. Validate configuration after changes:"
echo "   pve-firewall compile"
echo "   pve-firewall status"
echo
echo "Documentation: https://pve.proxmox.com/wiki/Firewall"
echo

exit 0
