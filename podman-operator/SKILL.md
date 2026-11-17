---
name: podman-operator
description: Build and operate Podman containers and Quadlet services, including rootless deployment, networking, volumes, systemd user integration, and troubleshooting.
---

# Podman Operator

Build, operate, and troubleshoot Podman containers, Quadlet systemd service units, and rootless environments.

## Core Operating Principles

1. **Rootless by Default**: Deploy containers as non-root users (`systemctl --user`) unless privileged host hardware access is explicitly required.
2. **Quadlet Unit Declarations**: Prefer Quadlet declarative service units (`.container`, `.volume`, `.network`, `.kube`) placed in `~/.config/containers/systemd/` over imperative container commands.
3. **Data Integrity & Volumes**:
   - Never delete volumes or named data mounts without explicit confirmation.
   - Retain previous container image tags and backup configuration before initiating upgrades.
4. **Security & Secrets**:
   - Never hardcode secrets in container definitions or unit files; use Podman secrets manager (`podman secret create`).
   - Preserve SELinux labels; handle denials using container-specific volume flags (`:Z` or `:z`).

## Diagnostic Commands

Gather container, networking, volume, and service status:

```bash
# Container lifecycle
podman ps -a
podman images
podman logs --tail 50 <container_name>
podman inspect <container_name>

# Storage and networking
podman network ls
podman volume ls

# Systemd user services (Quadlet)
systemctl --user status <service_name>
journalctl --user -xeu <service_name> --no-pager -n 50
systemctl --user daemon-reload
```

## Quadlet Workflow

1. Create or edit declarative units in `~/.config/containers/systemd/<app>.container`:
   ```ini
   [Unit]
   Description=My Rootless Container Service
   After=network-online.target

   [Container]
   Image=docker.io/library/alpine:latest
   Exec=sleep infinity
   PublishPort=8080:8080
   Volume=/host/data:/app/data:Z

   [Service]
   Restart=always

   [Install]
   WantedBy=default.target
   ```
2. Reload systemd generator:
   ```bash
   systemctl --user daemon-reload
   systemctl --user restart <app>
   ```
3. Verify status:
   ```bash
   systemctl --user is-active <app>
   podman ps --filter "name=<app>"
   ```
