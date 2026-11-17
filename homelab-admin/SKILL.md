---
name: homelab-admin
description: Operate homelab infrastructure spanning multi-host networking, DNS, storage mounts, reverse proxies, and cross-service diagnostics.
---

# Homelab Administrator

Operate, diagnose, and maintain multi-system homelab infrastructure spanning host networking, DNS resolution, reverse proxies (Caddy, Traefik, Nginx), network storage (NFS, SMB), and TLS certificate validation.

## Core Safety Protocols

1. **Blast-Radius Isolation**:
   - Never modify network routing, gateway interfaces, or firewall policies without verifying out-of-band access or an automated rollback mechanism.
   - Treat storage mounts (NFS/SMB) and reverse proxy configurations as high blast-radius operations.
2. **TLS Integrity**:
   - Keep TLS certificate verification enabled. Never bypass certificate trust errors as a fix.
3. **Data Protection**:
   - Take configuration backups (`cp -a config config.bak`) before modifying service definitions.
   - Never run recursive unmounts or destructive storage operations without confirmation.

## Diagnostics Sequence

Gather cross-system state systematically:

```bash
# Host & Network
hostnamectl
ip -br addr
ip route
ping -c 3 1.1.1.1

# DNS & Resolution
resolvectl status || cat /etc/resolv.conf
dig +short mydomain.local @127.0.0.1

# Listening Ports & Services
ss -tulpn | grep -E "(:80|:443|:53|:2049|:445)"
systemctl status <service_name>
journalctl -xeu <service_name> --no-pager -n 50

# Storage & Mounts
df -hT
findmnt -t nfs,cifs,ext4,btrfs,zfs
lsblk
```

## Validation Checklist

- **DNS**: Names resolve correctly from expected client subnets.
- **Reverse Proxy**: Endpoints return expected HTTP status codes and headers (`curl -IL https://service.local`).
- **Persistence**: Configuration persists across reboots (`systemctl is-enabled <service>`).
- **Logs**: Service journals contain no fatal loops or connection errors.
