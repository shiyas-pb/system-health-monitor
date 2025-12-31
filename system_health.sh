#!/usr/bin/env bash
# =========================================
# Production System Health Monitor Script
# =========================================

set -euo pipefail

# -------------------------------
# Configuration (overridable)
# -------------------------------
LOG_FILE="${LOG_FILE:-/var/log/system_health.log}"

CPU_THRESHOLD="${CPU_THRESHOLD:-80}"
MEM_THRESHOLD="${MEM_THRESHOLD:-80}"
DISK_THRESHOLD="${DISK_THRESHOLD:-85}"
LOAD_FACTOR="${LOAD_FACTOR:-1.5}"   # load > cores * factor => warning

STATUS=0   # 0 = OK, 1 = WARNING, 2 = ERROR

HOSTNAME="$(hostname 2>/dev/null | cut -d. -f1 || echo unknown)"

# -------------------------------
# Helper functions
# -------------------------------
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$HOSTNAME] - $1" | tee -a "$LOG_FILE" || true
}

set_status() {
    local level="${1:-0}"
    (( level > STATUS )) && STATUS="$level"
}

# -------------------------------
# Log file check
# -------------------------------
if ! touch "$LOG_FILE" 2>/dev/null; then
    echo "ERROR: Cannot write to $LOG_FILE (run as root or set LOG_FILE)" >&2
    exit 2
fi

log "===== System Health Check Started ====="

# -------------------------------
# CPU Usage (/proc/stat)
# -------------------------------
if read -r cpu u n s i iw irq sirq st _ < /proc/stat; then
    TOTAL_BEFORE=$((u + n + s + i + iw + irq + sirq + st))
    IDLE_BEFORE=$((i + iw))

    sleep 1

    if read -r cpu u n s i iw irq sirq st _ < /proc/stat; then
        TOTAL_AFTER=$((u + n + s + i + iw + irq + sirq + st))
        IDLE_AFTER=$((i + iw))

        if (( TOTAL_AFTER > TOTAL_BEFORE )); then
            CPU_USAGE=$(
                awk -v idle=$((IDLE_AFTER - IDLE_BEFORE)) \
                    -v total=$((TOTAL_AFTER - TOTAL_BEFORE)) \
                    'BEGIN { printf "%d", (1 - idle / total) * 100 }'
            )

            if (( CPU_USAGE > CPU_THRESHOLD )); then
                log "WARNING: CPU usage high: ${CPU_USAGE}%"
                set_status 1
            else
                log "OK: CPU usage: ${CPU_USAGE}%"
            fi
        else
            log "ERROR: CPU counters did not advance"
            set_status 2
        fi
    else
        log "ERROR: Failed second /proc/stat read"
        set_status 2
    fi
else
    log "ERROR: Failed first /proc/stat read"
    set_status 2
fi

# -------------------------------
# Memory Usage (MemAvailable)
# -------------------------------
if grep -q MemAvailable /proc/meminfo; then
    MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    MEM_AVAILABLE=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)

    if (( MEM_TOTAL > 0 )); then
        MEM_USAGE=$(( (MEM_TOTAL - MEM_AVAILABLE) * 100 / MEM_TOTAL ))

        if (( MEM_USAGE > MEM_THRESHOLD )); then
            log "WARNING: Memory usage high: ${MEM_USAGE}%"
            set_status 1
        else
            log "OK: Memory usage: ${MEM_USAGE}%"
        fi
    else
        log "ERROR: Invalid MemTotal value"
        set_status 2
    fi
else
    log "ERROR: MemAvailable not supported by kernel"
    set_status 2
fi

# -------------------------------
# Disk Usage (/ only)
# -------------------------------
if DISK_USAGE=$(df -P / 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}'); then
    if [[ "$DISK_USAGE" =~ ^[0-9]+$ ]]; then
        if (( DISK_USAGE > DISK_THRESHOLD )); then
            log "WARNING: Disk usage high on / : ${DISK_USAGE}%"
            set_status 1
        else
            log "OK: Disk usage on / : ${DISK_USAGE}%"
        fi
    else
        log "ERROR: Non-numeric disk usage value"
        set_status 2
    fi
else
    log "ERROR: Disk usage check failed"
    set_status 2
fi

# -------------------------------
# Load Average vs CPU cores (corrected variable names)
# -------------------------------
if LOAD_AVG=$(awk '{print $1}' /proc/loadavg 2>/dev/null) \
   && CPU_CORES=$(nproc 2>/dev/null); then

    LOAD_LIMIT=$(awk -v cores="$CPU_CORES" -v factor="$LOAD_FACTOR" 'BEGIN {printf "%.2f", cores * factor}')

    if awk -v avg="$LOAD_AVG" -v limit="$LOAD_LIMIT" 'BEGIN {exit !(avg > limit)}'; then
        log "WARNING: Load average high: ${LOAD_AVG} (limit: ${LOAD_LIMIT})"
        set_status 1
    else
        log "OK: Load average: ${LOAD_AVG}"
    fi
else
    log "ERROR: Load average or CPU core detection failed"
    set_status 2
fi

log "===== System Health Check Completed (STATUS=$STATUS) ====="
echo

exit "$STATUS"
