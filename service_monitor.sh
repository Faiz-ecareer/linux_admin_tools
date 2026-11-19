
#!/usr/bin/env bash

set -o nounset
set -o pipefail

# ==========================================
# SERVICE MONITOR
# ==========================================


# ==========================================
# CHECK SYSTEMD
# ==========================================

check_systemd() {

    if ! command -v systemctl &>/dev/null; then
        echo "[ERROR] systemctl is not available."
        exit 1
    fi

    if ! systemctl is-system-running &>/dev/null; then
        echo "[WARNING] System may be in a degraded state."
    fi
}


# ==========================================
# RUNNING SERVICES
# ==========================================

running_services() {

    echo
    echo "========== RUNNING SERVICES =========="

    systemctl list-units \
        --type=service \
        --state=running \
        --no-pager
}


# ==========================================
# FAILED SERVICES
# ==========================================

failed_services() {

    echo
    echo "========== FAILED SERVICES =========="

    if systemctl --failed --type=service --no-legend --no-pager |
        grep -q .; then

        systemctl --failed --type=service --no-pager

    else
        echo "[HEALTHY] No failed services found."
    fi
}


# ==========================================
# CHECK INDIVIDUAL SERVICE
# ==========================================

check_service() {

    echo
    echo "========== INDIVIDUAL SERVICE CHECK =========="

    local service

    read -rp "Enter service name (e.g. ssh): " service

    if [[ -z "$service" ]]; then
        echo "[ERROR] Service name cannot be empty."
        return
    fi

    if [[ ! "$service" =~ ^[a-zA-Z0-9_.@:-]+$ ]]; then
        echo "[ERROR] Invalid service name."
        return
    fi

    if [[ "$service" != *.service ]]; then
        service="${service}.service"
    fi

    echo
    echo "Service: $service"

    echo
    echo "Active Status:"
    systemctl is-active "$service" || true

    echo
    echo "Boot Status:"
    systemctl is-enabled "$service" || true

    echo
    echo "Detailed Status:"
    systemctl status "$service" --no-pager -l || true
}


# ==========================================
# SYSTEMD SERVICE SUMMARY
# ==========================================

service_summary() {

    echo
    echo "========== SERVICE SUMMARY =========="

    local running failed

    running=$(systemctl list-units \
        --type=service \
        --state=running \
        --no-legend | wc -l)

    failed=$(systemctl --failed \
        --type=service \
        --no-legend | wc -l)

    echo "Running Services : $running"
    echo "Failed Services  : $failed"

    if (( failed > 0 )); then
        echo "[WARNING] Failed services detected."
    else
        echo "[HEALTHY] No failed services."
    fi
}


# ==========================================
# MAIN MENU
# ==========================================

main() {

    check_systemd

    while true; do

        echo
        echo "=========================================="
        echo "           LINUX SERVICE MONITOR"
        echo "=========================================="

        echo "1. Service Summary"
        echo "2. List Running Services"
        echo "3. List Failed Services"
        echo "4. Check Individual Service"
        echo "5. Exit"

        echo "=========================================="

        local choice

        read -rp "Enter your choice: " choice

        case "$choice" in

            1) service_summary ;;
            2) running_services ;;
            3) failed_services ;;
            4) check_service ;;
            5)
                echo "Exiting Service Monitor."
                break
                ;;
            *)
                echo "[ERROR] Invalid choice."
                ;;
        esac

    done
}

main "$@"
