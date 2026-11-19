
#!/bin/bash

# SSH SECURITY AUDIT SCRIPT

echo "=========================================="
echo "             SSH SECURITY AUDIT"
echo "=========================================="

# Detect SSH server executable
SSHD=$(command -v sshd 2>/dev/null)

if [[ -z "$SSHD" && -x /usr/sbin/sshd ]]; then
    SSHD="/usr/sbin/sshd"
fi

if [[ -z "$SSHD" ]]; then
    echo
    echo "[ERROR] SSH server (sshd) is not installed"
    exit 1
fi

# Check SSH service status
echo
echo "========== SSH SERVICE STATUS =========="

if systemctl is-active --quiet ssh; then
    echo "[OK] SSH service is running"
else
    echo "[WARNING] SSH service is not running"
fi

if systemctl is-enabled --quiet ssh 2>/dev/null; then
    echo "[OK] SSH is enabled at boot"
else
    echo "[WARNING] SSH is not enabled at boot"
fi

# Read effective SSH configuration
echo
echo "========== SSH SERVER CONFIGURATION =========="

SSH_CONFIG=$(sudo "$SSHD" -T 2>/dev/null)

if [[ -z "$SSH_CONFIG" ]]; then
    echo "[ERROR] Unable to read effective SSH configuration"
    exit 1
fi

ROOT_LOGIN=$(awk '$1=="permitrootlogin"{print $2}' <<< "$SSH_CONFIG")
PASSWORD_AUTH=$(awk '$1=="passwordauthentication"{print $2}' <<< "$SSH_CONFIG")
PUBKEY_AUTH=$(awk '$1=="pubkeyauthentication"{print $2}' <<< "$SSH_CONFIG")
SSH_PORT=$(awk '$1=="port"{print $2; exit}' <<< "$SSH_CONFIG")

echo "SSH Port                  : $SSH_PORT"
echo "Root Login                : $ROOT_LOGIN"
echo "Password Authentication   : $PASSWORD_AUTH"
echo "Public Key Authentication : $PUBKEY_AUTH"

# Security checks
echo
echo "========== SECURITY CHECKS =========="

if [[ "$ROOT_LOGIN" == "no" || "$ROOT_LOGIN" == "prohibit-password" || "$ROOT_LOGIN" == "forced-commands-only" ]]; then
    echo "[OK] Root login is restricted"
else
    echo "[WARNING] Root login is permitted"
fi

if [[ "$PASSWORD_AUTH" == "no" ]]; then
    echo "[OK] Password authentication is disabled"
else
    echo "[WARNING] Password authentication is enabled"
fi

if [[ "$PUBKEY_AUTH" == "yes" ]]; then
    echo "[OK] Public key authentication is enabled"
else
    echo "[WARNING] Public key authentication is disabled"
fi

# Listening ports
echo
echo "========== SSH LISTENING PORTS =========="

if command -v ss &>/dev/null; then
    sudo ss -tlnp | grep -E 'State|sshd' || true
else
    echo "[WARNING] ss command is unavailable"
fi

# SSH configuration validation
echo
echo "========== CONFIGURATION VALIDATION =========="

if sudo "$SSHD" -t 2>/dev/null; then
    echo "[OK] SSH configuration syntax is valid"
else
    echo "[ERROR] SSH configuration validation failed"
fi

# Failed login attempts
echo
echo "========== FAILED SSH LOGIN ATTEMPTS =========="
echo "Period: Last 7 days"

if command -v journalctl &>/dev/null; then

    FAILED_LOGINS=$(sudo journalctl -u ssh --since "7 days ago" --no-pager -q 2>/dev/null |
        grep -Eic 'Failed password|Invalid user|authentication failure' || true)

    echo "Failed login events: $FAILED_LOGINS"

    if [[ "$FAILED_LOGINS" -gt 0 ]]; then
        echo "[WARNING] Failed SSH login attempts detected"
    else
        echo "[OK] No failed login events found in accessible journal logs"
    fi

else
    echo "[WARNING] journalctl is unavailable"
fi

echo
echo "=========================================="
echo "           SSH AUDIT COMPLETED"
echo "=========================================="
