### Simple System Monitor Script

This is a very basic Linux shell script.

It shows:
- CPU usage
- Memory usage
- Disk usage

## What you need
- Linux system
- Bash shell

## How to run

1. Save the script as `system_monitor.sh`

2. Give execute permission:
   ```bash
   chmod +x system_health.sh
   ```
3. Run the script:
   ```bash
   ./system_health.sh
   ```

### What the commands mean

top → shows CPU usage

free → shows memory usage

df → shows disk usage

awk → picks specific values from output
