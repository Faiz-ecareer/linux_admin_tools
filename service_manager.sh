
#!/bin/bash

SYSTEMCTL="/usr/bin/systemctl"

if [[ ! -x "$SYSTEMCTL" ]]; then
    SYSTEMCTL="/bin/systemctl"
fi

if [[ ! -x "$SYSTEMCTL" ]]; then
    echo "[ERROR] systemctl was not found."
    exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
    echo "[ERROR] Root privileges are required."
    echo "Run: sudo ./service_manager.sh"
    exit 1
fi

get_service() {
    local service

    read -rp "Enter service name: " service

    if [[ -z "$service" ]]; then
        echo "[ERROR] Service name cannot be empty."
        return 1
    fi

    if [[ ! "$service" =~ ^[a-zA-Z0-9_.@:-]+$ ]]; then
        echo "[ERROR] Invalid service name."
        return 1
    fi

    if [[ "$service" != *.service ]]; then
        service="${service}.service"
    fi

    local load_state
    load_state=$("$SYSTEMCTL" show "$service" --property=LoadState --value 2>/dev/null)

    if [[ "$load_state" == "not-found" || -z "$load_state" ]]; then
        echo "[ERROR] Service '$service' was not found."
        return 1
    fi

    SERVICE="$service"
    return 0
}

manage_service() {
    local action="$1"

    if ! get_service; then
        return
    fi

    echo
    echo "Performing '$action' on $SERVICE..."

    if "$SYSTEMCTL" "$action" "$SERVICE"; then
        echo "[SUCCESS] $action completed for $SERVICE."
    else
        echo "[ERROR] Failed to $action $SERVICE."
    fi
}

show_status() {
    if ! get_service; then
        return
    fi

    echo
    echo "========== SERVICE STATUS =========="
    echo "Service: $SERVICE"

    echo "Active state:"
    "$SYSTEMCTL" is-active "$SERVICE" 2>/dev/null || true

    echo
    echo "Boot state:"
    "$SYSTEMCTL" is-enabled "$SERVICE" 2>/dev/null || true

    echo
    "$SYSTEMCTL" status "$SERVICE" --no-pager -l 2>&1 || true
}

while true; do
    echo
    echo "===================================="
    echo "        SERVICE MANAGER"
    echo "===================================="
    echo "1. Start service"
    echo "2. Stop service"
    echo "3. Restart service"
    echo "4. Reload service"
    echo "5. Enable service at boot"
    echo "6. Disable service at boot"
    echo "7. Check service status"
    echo "8. Exit"
    echo "===================================="

    read -rp "Choose an option: " choice

    case "$choice" in
        1) manage_service start ;;
        2) manage_service stop ;;
        3) manage_service restart ;;
        4) manage_service reload ;;
        5) manage_service enable ;;
        6) manage_service disable ;;
        7) show_status ;;
        8)
            echo "Exiting Service Manager."
            exit 0
            ;;
        *)
            echo "[ERROR] Invalid option. Choose 1-8."
            ;;
    esac
done
