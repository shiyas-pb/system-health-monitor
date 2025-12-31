#!/bin/bash

# This script checks basic system health
# It shows CPU, Memory, and Disk usage

echo "System Health Check"
echo "-------------------"

# -------- CPU USAGE --------
# top shows CPU info
# 100 - idle percentage = used CPU
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')

echo "CPU Usage: ${CPU}%"

# -------- MEMORY USAGE --------
# free shows memory info
TOTAL_MEM=$(free -m | awk '/Mem:/ {print $2}')
USED_MEM=$(free -m | awk '/Mem:/ {print $3}')

MEM_PERCENT=$(( USED_MEM * 100 / TOTAL_MEM ))

echo "Memory Usage: ${MEM_PERCENT}%"

# -------- DISK USAGE --------
# df shows disk usage
DISK=$(df -h / | awk 'NR==2 {print $5}')

echo "Disk Usage: ${DISK}"

echo "-------------------"
echo "Check Completed"
