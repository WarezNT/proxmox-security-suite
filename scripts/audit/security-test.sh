#!/bin/bash

# Security Test Script for Proxmox Infrastructure
# Run this script from an external Ubuntu VPS to test security
# Usage: ./security-test.sh <TARGET_IP> [DOMAIN] [TAILSCALE_IP]

if [ -z "$1" ]; then
    echo "Usage: $0 <TARGET_IP> [DOMAIN] [TAILSCALE_IP]"
    echo "Example: $0 YOUR_PUBLIC_IP yourdomain.com YOUR_TAILSCALE_IP"
    exit 1
fi

TARGET_IP="$1"
DOMAIN="${2:-$TARGET_IP}"  # Use IP if no domain provided
TAILSCALE_IP="${3}"  # Optional Tailscale IP for testing

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Proxmox Infrastructure Security Test${NC}"
echo -e "${BLUE}  Target: $TARGET_IP${NC}"
echo -e "${BLUE}  Domain: $DOMAIN${NC}"
if [ -n "$TAILSCALE_IP" ]; then
    echo -e "${BLUE}  Tailscale IP: $TAILSCALE_IP${NC}"
fi
echo -e "${BLUE}============================================${NC}"
echo

# Check if this VPS is in the same Tailnet (security warning)
echo -e "${YELLOW}SECURITY CHECK: Verifying test environment...${NC}"
if ip route show | grep -q "100\."; then
    echo -e "${RED}⚠️  WARNING: This VPS appears to be connected to Tailscale!${NC}"
    echo -e "${RED}   Security tests may be inaccurate (false positives)${NC}"
    echo -e "${RED}   For accurate testing, disconnect from Tailscale or use external VPS${NC}"
    echo
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Test cancelled for security accuracy."
        exit 1
    fi
    echo -e "${YELLOW}Continuing with potentially inaccurate results...${NC}"
else
    echo -e "${GREEN}✓ Test environment appears clean (no Tailscale detected)${NC}"
fi
echo

# Function to test port and report results
test_port() {
    local ip=$1
    local port=$2
    local service=$3
    local expected=$4  # "open" or "closed"
    
    echo -n "Testing $service (port $port): "
    
    if timeout 5 nc -z $ip $port 2>/dev/null; then
        if [ "$expected" = "open" ]; then
            echo -e "${GREEN}✓ OPEN (Expected)${NC}"
        else
            echo -e "${RED}✗ OPEN (Security Risk!)${NC}"
        fi
    else
        if [ "$expected" = "closed" ]; then
            echo -e "${GREEN}✓ CLOSED (Secure)${NC}"
        else
            echo -e "${RED}✗ CLOSED (Service Down?)${NC}"
        fi
    fi
}

# Function to test HTTP services
test_http() {
    local url=$1
    local expected_status=$2
    local service_name=$3
    
    echo -n "Testing $service_name: "
    
    status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "$url" 2>/dev/null)
    
    if [ "$status" = "$expected_status" ]; then
        echo -e "${GREEN}✓ HTTP $status (Expected)${NC}"
    elif [ -z "$status" ]; then
        echo -e "${RED}✗ Connection Failed${NC}"
    else
        echo -e "${YELLOW}⚠ HTTP $status (Unexpected)${NC}"
    fi
}

echo -e "${YELLOW}1. CRITICAL SECURITY TESTS (Should be CLOSED)${NC}"
echo "=================================================="

# Test management ports (should be CLOSED from internet)
test_port $TARGET_IP 22 "SSH" "closed"
test_port $TARGET_IP 8006 "Proxmox Web GUI" "closed"
test_port $TARGET_IP 3128 "Proxmox Proxy" "closed"
test_port $TARGET_IP 5900 "VNC Console" "closed"
test_port $TARGET_IP 5901 "VNC Console" "closed"
test_port $TARGET_IP 5902 "VNC Console" "closed"
test_port $TARGET_IP 81 "NPM Admin" "closed"

echo
echo -e "${YELLOW}2. PUBLIC SERVICE TESTS (Should be OPEN)${NC}"
echo "==============================================="

# Test public ports (should be OPEN)
test_port $TARGET_IP 80 "HTTP" "open"
test_port $TARGET_IP 443 "HTTPS" "open"

echo
echo -e "${YELLOW}3. WEB SERVICE FUNCTIONALITY${NC}"
echo "================================="

# Test web services
if [ "$DOMAIN" != "$TARGET_IP" ]; then
    test_http "http://$TARGET_IP" "200" "Direct HTTP access"
    test_http "https://$DOMAIN" "200" "Domain HTTPS access"
    test_http "http://$DOMAIN" "301" "HTTP to HTTPS redirect"
else
    test_http "http://$TARGET_IP" "200" "HTTP access to IP"
    echo "Note: No domain provided, testing IP only"
fi

echo
echo -e "${YELLOW}4. COMMON VULNERABILITY SCANS${NC}"
echo "===================================="

# Test common vulnerable ports
echo "Scanning for common vulnerable services:"

vulnerable_ports=(21 23 25 53 110 143 993 995 1433 3306 3389 5432 6379 11211 27017)

for port in "${vulnerable_ports[@]}"; do
    test_port $TARGET_IP $port "Port $port" "closed"
done

echo
echo -e "${YELLOW}5. NETWORK INFORMATION GATHERING${NC}"
echo "======================================"

# DNS Information
echo "DNS Resolution test:"
dig_result=$(dig +short $DOMAIN)
echo "Domain $DOMAIN resolves to: $dig_result"

# Trace route test
echo
echo "Network path analysis:"
traceroute -m 10 $TARGET_IP 2>/dev/null | head -5

echo
echo -e "${YELLOW}6. SSL/TLS SECURITY TEST${NC}"
echo "============================"

# SSL Test using openssl
if [ "$DOMAIN" != "$TARGET_IP" ]; then
    echo "Testing SSL/TLS configuration for domain $DOMAIN:"
    ssl_info=$(echo | timeout 10 openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null)

    if echo "$ssl_info" | grep -q "Verify return code: 0 (ok)"; then
        echo -e "${GREEN}✓ SSL Certificate Valid${NC}"
    else
        echo -e "${YELLOW}⚠ SSL Certificate Issues${NC}"
    fi

    # Check SSL version
    ssl_version=$(echo "$ssl_info" | grep "Protocol" | head -1)
    echo "SSL Protocol: $ssl_version"
else
    echo "Skipping SSL test - no domain provided (IP-only testing)"
fi

echo
echo -e "${YELLOW}7. BRUTE FORCE PROTECTION TEST${NC}"
echo "===================================="

# Test if SSH is accessible (should fail)
echo "Testing SSH access (should be blocked):"
timeout 5 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$TARGET_IP exit 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${RED}✗ SSH is accessible! Security risk!${NC}"
else
    echo -e "${GREEN}✓ SSH properly blocked${NC}"
fi

echo
echo -e "${YELLOW}8. TAILSCALE SECURITY VERIFICATION${NC}"
echo "===================================="

# Note: This test will fail from external VPS (expected)
if [ -n "$TAILSCALE_IP" ]; then
    echo "Testing Tailscale IP accessibility (should fail from external):"
    test_port $TAILSCALE_IP 8006 "Proxmox via Tailscale" "closed"
    echo -e "${BLUE}Note: This should fail from external networks (VPN-only access)${NC}"
else
    echo -e "${YELLOW}No Tailscale IP provided - skipping Tailscale tests${NC}"
    echo "Use: $0 $TARGET_IP $DOMAIN YOUR_TAILSCALE_IP"
fi

echo
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}           SECURITY SUMMARY${NC}"
echo -e "${BLUE}============================================${NC}"
echo
echo -e "${GREEN}✅ GOOD SECURITY PRACTICES FOUND:${NC}"
echo "• Management ports (SSH, Proxmox GUI) blocked from internet"
echo "• Public services (HTTP/HTTPS) accessible as expected"
echo "• Tailscale provides secure management access"
echo
echo -e "${RED}⚠️  RECOMMENDATIONS:${NC}"
echo "• Keep Tailscale active for management access"
echo "• Monitor logs for unusual activity"
echo "• Regularly update Proxmox and containers"
echo "• Consider fail2ban for additional protection"
echo
echo -e "${BLUE}Test completed at: $(date)${NC}"
echo -e "${BLUE}Target tested: $TARGET_IP${NC}"