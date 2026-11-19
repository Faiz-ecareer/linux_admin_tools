
#!/usr/bin/env bash

set -o nounset
set -o pipefail

# ==========================================
# SYSTEM INFORMATION
# ==========================================

system_info() {
    echo
    echo "========== SYSTEM INFORMATION =========="

    source /etc/os-release

    printf "Hostname        : %s\n" "$(hostname)"
    printf "Operating System: %s\n" "${PRETTY_NAME:-Unknown}"
    printf "Kernel          : %s\n" "$(uname -r)"
    printf "Uptime          : %s\n" "$(uptime -p)"
}


# ==========================================
# CPU INFORMATION
# ==========================================

cpu_info() {
    echo
    echo "========== CPU INFORMATION =========="

    lscpu | awk -F: '/Model name/ {
        gsub(/^[ \t]+/, "", $2)
        print "CPU Model       : " $2
        exit
    }'

    echo "CPU Load Average: $(awk '{print $1, $2, $3}' /proc/loadavg)"
}


# ==========================================
# MEMORY INFORMATION
# ==========================================

memory_info() {
    echo
    echo "========== MEMORY INFORMATION =========="

    free -h
}


# ==========================================
# DISK INFORMATION
# ==========================================

disk_info() {
    echo
    echo "========== DISK INFORMATION =========="

    df -hT
}


# ==========================================
# NETWORK INFORMATION
# ==========================================

network_info() {
    echo
    echo "========== NETWORK INFORMATION =========="

    ip -br address
}


# ==========================================
# THRESHOLD CHECK FUNCTION
# ==========================================

check_threshold() {

    local name="$1"
    local usage="$2"
    local warning="$3"
    local critical="$4"

    if (( usage >= critical )); then
        printf "[CRITICAL] %-12s Usage: %s%%\n" "$name" "$usage"

    elif (( usage >= warning )); then
        printf "[WARNING]  %-12s Usage: %s%%\n" "$name" "$usage"

    else
        printf "[HEALTHY]  %-12s Usage: %s%%\n" "$name" "$usage"
    fi
}


# ==========================================
# DISK HEALTH CHECK
# ==========================================

check_disk() {

    local disk_usage

    disk_usage=$(df -P / | awk 'NR==2 {
        gsub(/%/, "", $5)
        print $5
    }')

    check_threshold "Disk" "$disk_usage" 80 90
}


# ==========================================
# MEMORY HEALTH CHECK
# ==========================================

check_memory() {

    local memory_usage

    memory_usage=$(free -b | awk '/^Mem:/ {
        printf "%.0f", (($2 - $7) / $2) * 100
    }')

    check_threshold "Memory" "$memory_usage" 80 90
}


# ==========================================
# CPU HEALTH CHECK
# ==========================================

check_cpu() {

    local total_1 idle_1 total_2 idle_2
    local total_diff idle_diff cpu_usage

    read -r total_1 idle_1 < <(
        awk '/^cpu / {
            total = 0
            for (i = 2; i <= NF; i++)
                total += $i
            print total, $5 + $6
        }' /proc/stat
    )

    sleep 1

    read -r total_2 idle_2 < <(
        awk '/^cpu / {
            total = 0
            for (i = 2; i <= NF; i++)
                total += $i
            print total, $5 + $6
        }' /proc/stat
    )

    total_diff=$((total_2 - total_1))
    idle_diff=$((idle_2 - idle_1))

    if (( total_diff <= 0 )); then
        echo "[UNKNOWN]  CPU usage could not be calculated."
        return
    fi

    cpu_usage=$(( (total_diff - idle_diff) * 100 / total_diff ))

    check_threshold "CPU" "$cpu_usage" 80 95
}


# ==========================================
# SYSTEM HEALTH SUMMARY
# ==========================================

health_info() {

    echo
    echo "========== SYSTEM HEALTH =========="

    check_cpu
    check_memory
    check_disk
}


# ==========================================
# MAIN FUNCTION
# ==========================================

main() {

    system_info
    cpu_info
    memory_info
    disk_info
    network_info
    health_info

    echo
    echo "========== HEALTH CHECK COMPLETED =========="
}

main "$@"
