
#!/bin/bash

# LINUX NETWORK AUDIT SCRIPT

echo "=========================================="
echo "             NETWORK AUDIT"
echo "=========================================="

# Network interfaces and IP addresses
echo
echo "========== NETWORK INTERFACES =========="

ip -brief address

# Interface operational status
echo
echo "========== INTERFACE STATUS =========="

ip -brief link

# Default gateway
echo
echo "========== DEFAULT GATEWAY =========="

GATEWAY=$(ip route | awk '$1=="default" {print $3; exit}')

if [[ -n "$GATEWAY" ]]; then
    echo "Default Gateway: $GATEWAY"
else
    echo "[WARNING] No default gateway configured"
fi

# Routing table
echo
echo "========== ROUTING TABLE =========="

ip route

# DNS configuration
echo
echo "========== DNS CONFIGURATION =========="

if command -v resolvectl &>/dev/null; then
    resolvectl status
elif [[ -f /etc/resolv.conf ]]; then
    cat /etc/resolv.conf
else
    echo "[WARNING] DNS configuration unavailable"
fi

# Internet connectivity
echo
echo "========== INTERNET CONNECTIVITY =========="

if ping -c 2 -W 3 1.1.1.1 &>/dev/null; then
    echo "[OK] Internet connectivity by IP is working"
else
    echo "[WARNING] Unable to reach 1.1.1.1"
fi

# DNS resolution
echo
echo "========== DNS RESOLUTION =========="

if getent ahosts google.com &>/dev/null; then
    echo "[OK] DNS resolution is working"
else
    echo "[WARNING] DNS resolution failed"
fi

# HTTPS connectivity
echo
echo "========== HTTPS CONNECTIVITY =========="

if command -v curl &>/dev/null; then
    HTTP_STATUS=$(curl -sS -o /dev/null -w "%{http_code}" \
        --connect-timeout 5 --max-time 10 https://example.com 2>/dev/null)

    if [[ "$HTTP_STATUS" =~ ^[23][0-9][0-9]$ ]]; then
        echo "[OK] HTTPS connectivity is working (HTTP $HTTP_STATUS)"
    else
        echo "[WARNING] HTTPS connectivity failed (HTTP $HTTP_STATUS)"
    fi
else
    echo "[WARNING] curl is unavailable"
fi

# Listening TCP ports
echo
echo "========== LISTENING TCP PORTS =========="

ss -tln

# Listening UDP ports
echo
echo "========== LISTENING UDP PORTS =========="

ss -uln

# Network interface statistics
echo
echo "========== NETWORK INTERFACE STATISTICS =========="

ip -s link

echo
echo "=========================================="
echo "           NETWORK AUDIT COMPLETED"
echo "=========================================="
