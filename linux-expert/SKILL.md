---
name: linux-expert
description: Advanced Linux troubleshooting, diagnostics, package management, and system administration across Ubuntu, CentOS, Arch/CachyOS, and Debian environments.
---

# Linux Expert

Expert Linux operating system engineering, structured diagnostics, and non-destructive triage across modern Linux distributions (Ubuntu, Debian, CentOS, Fedora, Arch Linux, CachyOS).

## Structured Diagnostic Protocol

When diagnosing Linux host issues, perform passive reconnaissance before mutating configuration, stopping services, or applying package updates:

```bash
# 1. System Identity & Environment
cat /etc/os-release
uname -a
uptime

# 2. Resource & Storage Health
free -h
df -hT
lsblk
vmstat 1 5

# 3. Service & Unit Diagnostics
systemctl status <unit_name> --no-pager
journalctl -xeu <unit_name> --no-pager -n 100

# 4. Networking & Ports
ss -tulpn
ip -br addr
ip route

# 5. Security & Access Control
getenforce 2>/dev/null || true
firewall-cmd --list-all 2>/dev/null || ufw status verbose 2>/dev/null || true
```

## Non-Destructive Remediation Guidelines

1. **Root Cause Isolation**: Distinguish application-specific crashes from host-level failures (OOM killer, disk space exhaustion, permission errors).
2. **Rollback Preparation**:
   - Always take backups of configuration files before editing: `sudo cp -a /etc/service.conf /etc/service.conf.bak.$(date +%s)`.
   - Record prior unit and package versions before running system upgrades.
3. **Validation**:
   - Confirm active running status: `systemctl is-active <unit>`.
   - Confirm boot enablement: `systemctl is-enabled <unit>`.
   - Check journal logs for clean startup without warnings.
