
#!/bin/bash

# LINUX PROCESS MONITOR

echo "=========================================="
echo "             PROCESS MONITOR"
echo "=========================================="

# Process summary
echo
echo "========== PROCESS SUMMARY =========="

TOTAL=$(ps -e --no-headers | wc -l)
RUNNING=$(ps -e -o stat= | grep -c '^R' || true)
SLEEPING=$(ps -e -o stat= | grep -c '^S' || true)
STOPPED=$(ps -e -o stat= | grep -c '^T' || true)
ZOMBIE=$(ps -e -o stat= | grep -c '^Z' || true)

echo "Total Processes   : $TOTAL"
echo "Running Processes : $RUNNING"
echo "Sleeping Processes: $SLEEPING"
echo "Stopped Processes : $STOPPED"
echo "Zombie Processes  : $ZOMBIE"

# CPU utilization
echo
echo "========== CPU UTILIZATION =========="

CPU_IDLE=$(top -bn1 | awk -F'[, ]+' '/Cpu\(s\)/ {for(i=1;i<=NF;i++) if($i=="id") {print $(i-1); exit}}')

if [[ -n "$CPU_IDLE" ]]; then
    CPU_USAGE=$(awk -v idle="$CPU_IDLE" 'BEGIN {printf "%.2f", 100-idle}')
    echo "CPU Usage: $CPU_USAGE%"
else
    echo "[WARNING] Unable to determine CPU usage"
fi

# Memory utilization
echo
echo "========== MEMORY UTILIZATION =========="

free -h

# Swap utilization
echo
echo "========== SWAP UTILIZATION =========="

free -h | awk 'NR==1 || NR==3'

# Top CPU-consuming processes
echo
echo "========== TOP 10 CPU-CONSUMING PROCESSES =========="

ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 11

# Top memory-consuming processes
echo
echo "========== TOP 10 MEMORY-CONSUMING PROCESSES =========="

ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -n 11

# Detailed process information
echo
echo "========== PROCESS INFORMATION =========="

ps -eo pid,ppid,user,stat,%cpu,%mem,comm --sort=-%cpu | head -n 16

echo
echo "=========================================="
echo "          PROCESS MONITOR COMPLETED"
echo "=========================================="
