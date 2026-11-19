
#!/bin/bash

# Linux Server Monitoring Script

# ---------------- CONFIGURATION ----------------

DISK_THRESHOLD=80
MEMORY_THRESHOLD=80
CPU_THRESHOLD=80

# ---------------- CHECK REQUIREMENTS ----------------

for CMD in uptime free df awk systemctl hostname; do
    if ! command -v "$CMD" &>/dev/null; then
        echo "[ERROR] Required command not found: $CMD"
        exit 1
    fi
done

# ---------------- SYSTEM INFORMATION ----------------

HOSTNAME=$(hostname)
OS=$(grep -m1 '^PRETTY_NAME=' /etc/os-release | cut -d '"' -f2)
KERNEL=$(uname -r)
UPTIME=$(uptime -p)

# ---------------- CPU UTILIZATION ----------------

CPU_USAGE=$(LC_ALL=C top -bn1 | awk -F',' '
/Cpu\(s\)/ {
    for (i=1; i<=NF; i++) {
        if ($i ~ / id/) {
            gsub(/[^0-9.]/, "", $i)
            print 100 - $i
            exit
        }
    }
}')

if [[ ! "$CPU_USAGE" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    CPU_USAGE=0
fi

# ---------------- MEMORY UTILIZATION ----------------

MEMORY_USAGE=$(free | awk '/Mem:/ {
    if ($2 > 0)
        printf "%.2f", ($3 / $2) * 100
    else
        print 0
}')

# ---------------- DISK UTILIZATION ----------------

DISK_REPORT=$(df -hP -x tmpfs -x devtmpfs | awk 'NR>1 {
    print $5, $6
}')

MAX_DISK_USAGE=$(df -P -x tmpfs -x devtmpfs | awk '
NR>1 {
    gsub(/%/, "", $5)
    if ($5 > max)
        max=$5
}
END {
    print max+0
}')

# ---------------- SYSTEM LOAD ----------------

LOAD_AVERAGE=$(awk '{print $1, $2, $3}' /proc/loadavg)

# ---------------- PROCESS INFORMATION ----------------

TOTAL_PROCESSES=$(ps -e --no-headers | wc -l)
RUNNING_PROCESSES=$(ps -e -o stat= | awk '$1 ~ /^R/ {count++} END {print count+0}')
ZOMBIE_PROCESSES=$(ps -e -o stat= | awk '$1 ~ /^Z/ {count++} END {print count+0}')

# ---------------- SERVICE INFORMATION ----------------

RUNNING_SERVICES=$(systemctl list-units --type=service --state=running --no-legend --no-pager | wc -l)

FAILED_SERVICES=$(systemctl list-units --type=service --state=failed --no-legend --no-pager)

FAILED_SERVICE_COUNT=$(printf '%s\n' "$FAILED_SERVICES" | awk 'NF {count++} END {print count+0}')

# ---------------- LOGGED-IN USERS ----------------

LOGGED_USERS=$(who | wc -l)

# ---------------- NETWORK INFORMATION ----------------

NETWORK_INTERFACES=$(ip -brief address 2>/dev/null)

# ---------------- HEALTH STATUS ----------------

CPU_STATUS="NORMAL"
MEMORY_STATUS="NORMAL"
DISK_STATUS="NORMAL"

if awk -v usage="$CPU_USAGE" -v threshold="$CPU_THRESHOLD" \
    'BEGIN {exit !(usage >= threshold)}'; then
    CPU_STATUS="HIGH"
fi

if awk -v usage="$MEMORY_USAGE" -v threshold="$MEMORY_THRESHOLD" \
    'BEGIN {exit !(usage >= threshold)}'; then
    MEMORY_STATUS="HIGH"
fi

if (( MAX_DISK_USAGE >= DISK_THRESHOLD )); then
    DISK_STATUS="HIGH"
fi

OVERALL_STATUS="HEALTHY"

if [[ "$CPU_STATUS" == "HIGH" ||
      "$MEMORY_STATUS" == "HIGH" ||
      "$DISK_STATUS" == "HIGH" ||
      "$FAILED_SERVICE_COUNT" -gt 0 ]]; then
    OVERALL_STATUS="WARNING"
fi

# ---------------- DISPLAY REPORT ----------------

echo "=================================================="
echo "              LINUX SERVER MONITOR"
echo "=================================================="

echo
echo "========== SYSTEM INFORMATION =========="

echo "Hostname          : $HOSTNAME"
echo "Operating System  : $OS"
echo "Kernel            : $KERNEL"
echo "Uptime            : $UPTIME"
echo "Date              : $(date '+%Y-%m-%d %H:%M:%S')"

echo
echo "========== CPU UTILIZATION =========="

printf "CPU Usage         : %.2f%%\n" "$CPU_USAGE"
echo "CPU Status        : $CPU_STATUS"

echo
echo "========== MEMORY UTILIZATION =========="

printf "Memory Usage      : %.2f%%\n" "$MEMORY_USAGE"
echo "Memory Status     : $MEMORY_STATUS"

echo
echo "========== DISK UTILIZATION =========="

echo "$DISK_REPORT"

echo
echo "Maximum Disk Usage: ${MAX_DISK_USAGE}%"
echo "Disk Status       : $DISK_STATUS"

echo
echo "========== SYSTEM LOAD =========="

echo "Load Average (1, 5, 15 min): $LOAD_AVERAGE"

echo
echo "========== PROCESS INFORMATION =========="

echo "Total Processes   : $TOTAL_PROCESSES"
echo "Running Processes : $RUNNING_PROCESSES"
echo "Zombie Processes  : $ZOMBIE_PROCESSES"

echo
echo "========== SERVICE INFORMATION =========="

echo "Running Services  : $RUNNING_SERVICES"
echo "Failed Services   : $FAILED_SERVICE_COUNT"

if [[ "$FAILED_SERVICE_COUNT" -gt 0 ]]; then
    echo
    echo "Failed Service Details:"
    printf '%s\n' "$FAILED_SERVICES"
fi

echo
echo "========== LOGGED-IN USERS =========="

echo "Logged-in Users   : $LOGGED_USERS"

echo
echo "========== NETWORK INTERFACES =========="

printf '%s\n' "$NETWORK_INTERFACES"

echo
echo "=================================================="
echo "              SERVER HEALTH SUMMARY"
echo "=================================================="

echo "Overall Status    : $OVERALL_STATUS"

echo
echo "CPU Threshold     : ${CPU_THRESHOLD}%"
echo "Memory Threshold  : ${MEMORY_THRESHOLD}%"
echo "Disk Threshold    : ${DISK_THRESHOLD}%"

echo
echo "Server Monitoring Completed."
echo "=================================================="
