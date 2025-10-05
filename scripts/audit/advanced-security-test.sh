#!/bin/bash

# Advanced Security Test Script for Proxmox Infrastructure
# This script performs more intensive security testing
# Usage: ./advanced-security-test.sh <TARGET_IP> [DOMAIN]

# Exit on error for better error handling
set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <TARGET_IP> [DOMAIN]"
    echo "Example: $0 YOUR_PUBLIC_IP yourdomain.com"
    exit 1
fi

TARGET_IP="$1"
DOMAIN="${2:-$TARGET_IP}"  # Use IP if no domain provided

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}    ADVANCED SECURITY PENETRATION TEST${NC}"
echo -e "${BLUE}    Target: $TARGET_IP${NC}"
echo -e "${BLUE}    Domain: $DOMAIN${NC}"
echo -e "${BLUE}============================================${NC}"

# Check if this VPS is in the same Tailnet (security warning)
echo -e "${YELLOW}SECURITY CHECK: Verifying test environment...${NC}"
if ip route show | grep -q "100\."; then
    echo -e "${RED}⚠️  CRITICAL WARNING: This VPS is connected to Tailscale!${NC}"
    echo -e "${RED}   Security penetration tests will be INACCURATE${NC}"
    echo -e "${RED}   Tailscale may bypass intended security restrictions${NC}"
    echo
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Test cancelled to ensure accurate security assessment."
        exit 1
    fi
    echo -e "${YELLOW}Continuing with HIGH RISK of inaccurate results...${NC}"
else
    echo -e "${GREEN}✓ Clean test environment (no Tailscale detected)${NC}"
fi
echo

# Check if tools are installed
check_tools() {
    echo "Checking required tools..."
    
    local tools=("nmap" "nikto" "curl" "dig" "traceroute" "openssl")
    local missing_tools=false
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}✓ $tool installed${NC}"
        else
            echo -e "${RED}✗ $tool not found${NC}"
            echo "Install with: sudo apt update && sudo apt install $tool"
            missing_tools=true
        fi
    done
    
    if [ "$missing_tools" = true ]; then
        echo -e "${YELLOW}Installing missing tools...${NC}"
        sudo apt update && sudo apt install -y nmap nikto curl dnsutils traceroute openssl
    fi
}

# Comprehensive port scan
port_scan() {
    echo -e "\n${YELLOW}1. COMPREHENSIVE PORT SCAN${NC}"
    echo "============================="
    
    echo "Scanning top 1000 ports..."
    nmap -T4 -F "$TARGET_IP" | grep -E "(open|closed|filtered)"
    
    echo -e "\nScanning management ports specifically..."
    nmap -p 22,8006,81,3128,5900-5920 "$TARGET_IP"
    
    echo -e "\nScanning for common services..."
    nmap -sV -p 80,443 "$TARGET_IP"
}

# Web vulnerability scan
web_vuln_scan() {
    echo -e "\n${YELLOW}2. WEB VULNERABILITY SCAN${NC}"
    echo "============================="
    
    if [ "$DOMAIN" != "$TARGET_IP" ]; then
        echo "Running Nikto web scanner on domain..."
        nikto -h "https://$DOMAIN" -maxtime 300 | head -20
        
        echo -e "\nTesting common web vulnerabilities on domain..."
        test_target="https://$DOMAIN"
    else
        echo "Running Nikto web scanner on IP..."
        nikto -h "http://$TARGET_IP" -maxtime 300 | head -20
        
        echo -e "\nTesting common web vulnerabilities on IP..."
        test_target="http://$TARGET_IP"
    fi
    
    # Test for common files
    local common_files=("robots.txt" "sitemap.xml" ".htaccess" "wp-admin" "admin" "phpmyadmin" "manager/html")
    
    for file in "${common_files[@]}"; do
        echo -n "Testing /$file: "
        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" "$test_target/$file")
        if [ "$status" = "200" ]; then
            echo -e "${YELLOW}Found (HTTP $status)${NC}"
        else
            echo -e "${GREEN}Not found (HTTP $status)${NC}"
        fi
    done
}

# SSL/TLS Deep Analysis
ssl_analysis() {
    echo -e "\n${YELLOW}3. SSL/TLS DEEP ANALYSIS${NC}"
    echo "=========================="
    
    if [ "$DOMAIN" != "$TARGET_IP" ]; then
        echo "Testing SSL configuration for domain $DOMAIN..."
        
        # Get certificate info
        local cert_info
        cert_info=$(echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -text)
        
        echo "Certificate issuer:"
        echo "$cert_info" | grep "Issuer:" | head -1
        
        echo "Certificate validity:"
        echo "$cert_info" | grep -A 2 "Validity"
        
        echo "Subject Alternative Names:"
        echo "$cert_info" | grep -A 1 "Subject Alternative Name" | tail -1
        
        # Test SSL versions
        echo -e "\nTesting SSL/TLS protocol support:"
        
        local protocols=("ssl2" "ssl3" "tls1" "tls1_1" "tls1_2" "tls1_3")
        
        for protocol in "${protocols[@]}"; do
            echo -n "Testing $protocol: "
            if echo | timeout 5 openssl s_client -connect "$DOMAIN:443" -"$protocol" 2>/dev/null | grep -q "Verify return code: 0"; then
                if [ "$protocol" = "ssl2" ] || [ "$protocol" = "ssl3" ] || [ "$protocol" = "tls1" ]; then
                    echo -e "${RED}Supported (Insecure!)${NC}"
                else
                    echo -e "${GREEN}Supported${NC}"
                fi
            else
                if [ "$protocol" = "ssl2" ] || [ "$protocol" = "ssl3" ] || [ "$protocol" = "tls1" ]; then
                    echo -e "${GREEN}Not supported (Good)${NC}"
                else
                    echo -e "${YELLOW}Not supported${NC}"
                fi
            fi
        done
    else
        echo "Skipping SSL analysis - no domain provided (IP-only testing)"
    fi
}

# HTTP Header Security Analysis
header_analysis() {
    echo -e "\n${YELLOW}4. HTTP SECURITY HEADERS${NC}"
    echo "========================="
    
    echo "Analyzing security headers..."
    
    local headers
    if [ "$DOMAIN" != "$TARGET_IP" ]; then
        headers=$(curl -s -I "https://$DOMAIN")
        echo "Testing HTTPS headers for $DOMAIN"
    else
        headers=$(curl -s -I "http://$TARGET_IP")
        echo "Testing HTTP headers for $TARGET_IP"
    fi
    
    local security_headers=(
        "Strict-Transport-Security"
        "Content-Security-Policy"
        "X-Frame-Options"
        "X-Content-Type-Options"
        "X-XSS-Protection"
        "Referrer-Policy"
        "Permissions-Policy"
    )
    
    for header in "${security_headers[@]}"; do
        echo -n "$header: "
        if echo "$headers" | grep -qi "$header"; then
            echo -e "${GREEN}Present${NC}"
        else
            echo -e "${YELLOW}Missing${NC}"
        fi
    done
    
    echo -e "\nServer information disclosure:"
    echo "$headers" | grep -i "server:"
    echo "$headers" | grep -i "x-powered-by:"
}

# DNS Security Analysis
dns_analysis() {
    echo -e "\n${YELLOW}5. DNS SECURITY ANALYSIS${NC}"
    echo "========================="
    
    echo "DNS records for $DOMAIN:"
    dig "$DOMAIN" ANY +short
    
    echo -e "\nChecking for DNS security features:"
    
    # Check DNSSEC
    echo -n "DNSSEC: "
    if dig "$DOMAIN" +dnssec | grep -q "RRSIG"; then
        echo -e "${GREEN}Enabled${NC}"
    else
        echo -e "${YELLOW}Not enabled${NC}"
    fi
    
    # Check SPF record
    echo -n "SPF Record: "
    if dig TXT "$DOMAIN" | grep -q "v=spf1"; then
        echo -e "${GREEN}Present${NC}"
    else
        echo -e "${YELLOW}Not found${NC}"
    fi
    
    # Check DMARC record
    echo -n "DMARC Record: "
    if dig TXT "_dmarc.$DOMAIN" | grep -q "v=DMARC1"; then
        echo -e "${GREEN}Present${NC}"
    else
        echo -e "${YELLOW}Not found${NC}"
    fi
}

# Rate limiting test
rate_limit_test() {
    echo -e "\n${YELLOW}6. RATE LIMITING TEST${NC}"
    echo "======================"
    
    echo "Testing rate limiting (making 20 rapid requests)..."
    
    local test_url
    if [ "$DOMAIN" != "$TARGET_IP" ]; then
        test_url="https://$DOMAIN"
    else
        test_url="http://$TARGET_IP"
    fi
    
    local success=0
    local blocked=0
    
    for i in {1..20}; do
        local status
        status=$(curl -s -o /dev/null -w "%{http_code}" "$test_url")
        if [ "$status" = "200" ]; then
            ((success++))
        elif [ "$status" = "429" ] || [ "$status" = "503" ]; then
            ((blocked++))
        fi
        sleep 0.1
    done
    
    echo "Successful requests: $success/20"
    echo "Blocked requests: $blocked/20"
    
    if [ "$blocked" -gt 0 ]; then
        echo -e "${GREEN}✓ Rate limiting appears to be active${NC}"
    else
        echo -e "${YELLOW}⚠ No rate limiting detected${NC}"
    fi
}

# Main execution
main() {
    check_tools
    port_scan
    web_vuln_scan
    ssl_analysis
    header_analysis
    dns_analysis
    rate_limit_test
    
    echo -e "\n${BLUE}============================================${NC}"
    echo -e "${BLUE}        ADVANCED TEST COMPLETE${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo
    echo -e "${GREEN}Key Security Recommendations:${NC}"
    echo "1. Ensure fail2ban is configured for brute force protection"
    echo "2. Add security headers in NPM custom configurations"
    echo "3. Monitor access logs regularly"
    echo "4. Keep all systems updated"
    echo "5. Consider implementing DNSSEC"
    echo
    echo "Test completed at: $(date)"
}

# Run main function
main