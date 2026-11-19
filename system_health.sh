
#!/usr/bin/env bash

# Linux System Health Monitoring Script

set -o nounset

# -------------------------------
# System Information
# -------------------------------

system_info() {
    echo "========== SYSTEM INFORMATION =========="
    echo "Hostname      : $(hostname)"
    echo "Operating System: $(. /etc/os-release && echo "$PRETTY_NAME")"
    echo "Kernel        : $(uname -r)"
    echo "Uptime        : $(uptime -p)"
}

# -------------------------------
# CPU Information
# -------------------------------

cpu_info() {
    echo
    echo "========== CPU INFORMATION =========="
    echo "CPU Model     : $(lscpu | awk -F: '/Model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}')"
    echo "Load Average  : $(awk '{print $1, $2, $3}' /proc/loadavg)"
}

# -------------------------------
# Memory Information
# -------------------------------

memory_info() {
    echo
    echo "========== MEMORY INFORMATION =========="
    free -h
}

# -------------------------------
# Disk Information
# -------------------------------

disk_info() {
    echo
    echo "========== DISK INFORMATION =========="
    df -hT
}

# -------------------------------
# Network Information
# -------------------------------

network_info() {
    echo
    echo "========== NETWORK INFORMATION =========="
    ip -br address
}

# -------------------------------
# Main Function
# -------------------------------

main() {
    system_info
    cpu_info
    memory_info
    disk_info
    network_info
}

main

