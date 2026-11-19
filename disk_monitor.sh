
#!/usr/bin/env bash

set -o nounset
set -o pipefail

# ==========================================
# DISK MONITOR
# ==========================================

# CONFIGURATION
WARNING_THRESHOLD=80
CRITICAL_THRESHOLD=90
TOP_DIRECTORIES=10


# ==========================================
# FILESYSTEM INFORMATION
# ==========================================

filesystem_info() {

    echo
    echo "========== FILESYSTEM INFORMATION =========="

    df -hT -x tmpfs -x devtmpfs
}


# ==========================================
# DISK USAGE MONITOR
# ==========================================

check_disk_usage() {

    echo
    echo "========== DISK USAGE MONITOR =========="

    df -P -x tmpfs -x devtmpfs | awk 'NR > 1 {
        usage = $5
        gsub(/%/, "", usage)

        printf "%-20s %5s%% used  %s available\n", $6, usage, $4

        if (usage >= 90) {
            print "[CRITICAL] Disk usage critical: " $6
        }
        else if (usage >= 80) {
            print "[WARNING] Disk usage high: " $6
        }
        else {
            print "[HEALTHY] Disk usage normal: " $6
        }

        print ""
    }'
}


# ==========================================
# INODE MONITOR
# ==========================================

check_inodes() {

    echo
    echo "========== INODE UTILIZATION =========="

    df -Pi -x tmpfs -x devtmpfs | awk 'NR > 1 {
        usage = $5
        gsub(/%/, "", usage)

        printf "%-20s %5s%% inodes used\n", $6, usage

        if (usage >= 90) {
            print "[CRITICAL] Inode usage critical: " $6
        }
        else if (usage >= 80) {
            print "[WARNING] Inode usage high: " $6
        }
        else {
            print "[HEALTHY] Inode utilization normal: " $6
        }

        print ""
    }'
}


# ==========================================
# LARGEST DIRECTORIES
# ==========================================

largest_directories() {

    echo
    echo "========== LARGEST DIRECTORIES =========="

    du -xhd1 / 2>/dev/null | sort -hr | head -n "$TOP_DIRECTORIES"
}


# ==========================================
# LARGEST FILES
# ==========================================

largest_files() {

    echo
    echo "========== TOP 10 LARGEST FILES =========="

    find / -xdev -type f -printf '%s %p\n' 2>/dev/null |
        sort -nr |
        head -n 10 |
        awk '{
            size = $1
            $1 = ""
            printf "%.2f MB %s\n", size / 1048576, $0
        }'
}


# ==========================================
# DISK SPACE SUMMARY
# ==========================================

disk_summary() {

    echo
    echo "========== DISK SPACE SUMMARY =========="

    df -h / | awk 'NR == 2 {
        printf "Total Space : %s\n", $2
        printf "Used Space  : %s\n", $3
        printf "Free Space  : %s\n", $4
        printf "Usage       : %s\n", $5
    }'
}


# ==========================================
# MAIN FUNCTION
# ==========================================

main() {

    echo
    echo "=========================================="
    echo "           LINUX DISK MONITOR"
    echo "=========================================="

    filesystem_info
    check_disk_usage
    check_inodes
    largest_directories
    largest_files
    disk_summary

    echo
    echo "========== DISK MONITORING COMPLETED =========="
}

main "$@"
