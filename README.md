### 🖥️ Production System Health Monitor (Bash)

A production-grade system health monitoring script written in Bash, designed for Linux servers.
It performs defensive, low-level checks using /proc, escalates severity correctly.

This project focuses on correctness, portability, and operational robustness.

### 📌 Features

✅ CPU usage calculation using /proc/stat (delta-based, not top)

✅ Memory usage based on MemAvailable (modern Linux accounting)

✅ Disk usage monitoring for /

✅ Load average validation with configurable tolerance

✅ Severity escalation (OK → WARNING → ERROR)

✅ Safe logging that never crashes the script

✅ Environment-configurable thresholds

✅ Portable across RHEL, Rocky, Ubuntu, and most containers

### 📂 Project Structure
```bash
.
├── system_health.sh
└── README.md
```

## ⚙️ Requirements

Linux kernel with /proc filesystem

Bash 

Standard utilities:

awk

df

hostname

nproc

No external dependencies.

## Usage
1️⃣ Make the script executable
```bash
chmod +x system_health.sh
```
2️⃣ Run manually
```bash
./system_health.sh
```
## 🔧 Configuration (Environment Variables)

All thresholds are runtime-configurable — no code changes required.
| Variable         | Default                      | Description                              |
| ---------------- | ---------------------------- | ---------------------------------------- |
| `CPU_THRESHOLD`  | `80`                         | CPU usage warning threshold (%)          |
| `MEM_THRESHOLD`  | `80`                         | Memory usage warning threshold (%)       |
| `DISK_THRESHOLD` | `85`                         | Disk usage warning threshold (%)         |
| `LOAD_FACTOR`    | `1.5`                        | Load > `cores × factor` triggers warning |
| `LOG_FILE`       | `/var/log/system_health.log` | Log file path                            |
