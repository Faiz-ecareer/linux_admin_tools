
#!/usr/bin/env bash

set -o nounset
set -o pipefail

# ==========================================
# RESOURCE MONITOR
# ==========================================

# CONFIGURATION
CPU_WARNING=80
MEMORY_WARNING=80
SWAP_WARNING=80


# ==========================================
# CPU MONITOR
# ==========================================

monitor_cpu() {

    echo
    echo "========== CPU MONITOR =========="

    local cpu_usage

    cpu_usage=$(top -bn2 -d 1 | awk '/Cpu\(s\)/ {
        idle = $8
        usage = 100 - idle
        value = usage
    } END {
        printf "%.0f", value
    }')

    echo "CPU Usage: ${cpu_usage}%"

    if (( cpu_usage >= CPU_WARNING )); then
        echo "[WARNING] High CPU utilization"
    else
        echo "[HEALTHY] CPU utilization normal"
    fi
}


# ==========================================
# MEMORY MONITOR
# ==========================================

monitor_memory() {

    echo
    echo "========== MEMORY MONITOR =========="

    free -h

    local memory_usage

    memory_usage=$(free -b | awk '/^Mem:/ {
        printf "%.0f", (($2 - $7) / $2) * 100
    }')

    echo
    echo "Memory Usage: ${memory_usage}%"

    if (( memory_usage >= MEMORY_WARNING )); then
        echo "[WARNING] High memory utilization"
    else
        echo "[HEALTHY] Memory utilization normal"
    fi
}


# ==========================================
# SWAP MONITOR
# ==========================================

monitor_swap() {

    echo
    echo "========== SWAP MONITOR =========="

    local swap_usage

    swap_usage=$(free -b | awk '/^Swap:/ {
        if ($2 == 0) {
            print 0
        } else {
            printf "%.0f", ($3 / $2) * 100
        }
    }')

    free -h | awk '/^Swap:/ {
        print "Total Swap: " $2
        print "Used Swap : " $3
        print "Free Swap : " $4
    }'

    echo "Swap Usage: ${swap_usage}%"

    if (( swap_usage >= SWAP_WARNING )); then
        echo "[WARNING] High swap utilization"
    else
        echo "[HEALTHY] Swap utilization normal"
    fi
}


# ==========================================
# SYSTEM LOAD
# ==========================================

monitor_load() {

    echo
    echo "========== SYSTEM LOAD =========="

    uptime

    echo
    echo "CPU Core Count: $(nproc)"

    echo "Load Average  : $(awk '{print $1, $2, $3}' /proc/loadavg)"
}


# ==========================================
# TOP CPU PROCESSES
# ==========================================

top_cpu_processes() {

    echo
    echo "========== TOP 5 CPU PROCESSES =========="

    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6
}


# ==========================================
# TOP MEMORY PROCESSES
# ==========================================

top_memory_processes() {

    echo
    echo "========== TOP 5 MEMORY PROCESSES =========="

    ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 6
}


# ==========================================
# MAIN FUNCTION
# ==========================================

main() {

    echo
    echo "=========================================="
    echo "         LINUX RESOURCE MONITOR"
    echo "=========================================="

    monitor_cpu
    monitor_memory
    monitor_swap
    monitor_load
    top_cpu_processes
    top_memory_processes

    echo
    echo "========== MONITORING COMPLETED =========="
}

main "$@"
