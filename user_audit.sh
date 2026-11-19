
#!/bin/bash

# LINUX USER ACCOUNT AUDIT

echo "=========================================="
echo "              USER ACCOUNT AUDIT"
echo "=========================================="

# Currently logged-in users
echo
echo "========== CURRENTLY LOGGED-IN USERS =========="

who

echo
echo "Total Logged-in Sessions: $(who | wc -l)"

# All user accounts
echo
echo "========== SYSTEM USER ACCOUNTS =========="

awk -F: '{
    printf "%-20s UID: %-8s GID: %-8s Shell: %s\n", $1, $3, $4, $7
}' /etc/passwd

# Regular user accounts
echo
echo "========== REGULAR USER ACCOUNTS =========="

awk -F: '$3 >= 1000 && $3 < 65534 {
    printf "%-20s UID: %-8s Home: %s\n", $1, $3, $6
}' /etc/passwd

# Sudo group members
echo
echo "========== USERS WITH SUDO GROUP MEMBERSHIP =========="

SUDO_USERS=$(getent group sudo | awk -F: '{print $4}')

if [[ -n "$SUDO_USERS" ]]; then
    echo "$SUDO_USERS" | tr ',' '\n'
else
    echo "No supplementary sudo group members found"
fi

# Accounts with valid login shells
echo
echo "========== ACCOUNTS WITH LOGIN SHELLS =========="

awk -F: '
    NR==FNR {
        if ($1 !~ /^#/ && NF) shells[$1]=1
        next
    }
    $7 in shells {
        print $1 " : " $7
    }
' /etc/shells /etc/passwd

# Account password status
echo
echo "========== ACCOUNT LOCK STATUS =========="

while IFS=: read -r USERNAME _; do

    STATUS=$(sudo passwd -S "$USERNAME" 2>/dev/null | awk '{print $2}')

    case "$STATUS" in
        L)
            echo "$USERNAME : Locked"
            ;;
        P)
            echo "$USERNAME : Password set (not locked)"
            ;;
        NP)
            echo "$USERNAME : No password set"
            ;;
        *)
            echo "$USERNAME : Status unavailable"
            ;;
    esac

done < /etc/passwd

# UID 0 accounts
echo
echo "========== UID 0 ACCOUNTS =========="

UID_ZERO=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)

if [[ -n "$UID_ZERO" ]]; then
    echo "$UID_ZERO"
else
    echo "[OK] No UID 0 accounts found"
fi

# Last login information
echo
echo "========== LAST LOGIN INFORMATION =========="

if command -v lastlog &>/dev/null; then
    sudo lastlog
else
    echo "[WARNING] lastlog command is unavailable"
fi

# Recent login history
echo
echo "========== RECENT LOGIN HISTORY =========="

if command -v last &>/dev/null; then
    last -n 10
else
    echo "[WARNING] last command is unavailable"
fi

echo
echo "=========================================="
echo "             AUDIT COMPLETED"
echo "=========================================="
