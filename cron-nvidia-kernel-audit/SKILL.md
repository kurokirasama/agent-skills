---
name: cron-nvidia-kernel-audit
description: Autonomously researches if it is safe to upgrade to the latest Ubuntu 24.04 HWE kernel with NVIDIA drivers.
cron: "0 12 * * 5" # Friday at 12:00
stateful: true
---

# cron-nvidia-kernel-audit

Autonomously researches and audits the safety of upgrading the Ubuntu 24.04 kernel for systems using NVIDIA GPUs and Hyprland (Wayland).

## Cron Wakeup Behavior

Upon wake, this skill performs the following steps:

1.  **Initialize State**:
    -   Read state from `skills/cron-nvidia-kernel-audit/state.json`.
    -   If missing, initialize with default values (status: "idle", recommendation: null).

2.  **Audit Pulse**:
    -   Check the `last_run` date. If it's the same day, stop to avoid redundant pulses.
    -   Update status to "researching".
    -   **Research**:
        -   Perform web research to find recent reports of "Black Screen", "Hard Freeze", or "NVIDIA DRM modeset failures" on Ubuntu 24.04 with kernels newer than 6.17.
        -   Prioritize: Ubuntu Forums, NVIDIA Forums, Hyprland GitHub Issues.
    -   **Analyze**:
        -   Determine if NVIDIA driver updates or kernel patches have resolved the incompatibility.
        -   Set recommendation to "GO" or "NO-GO".
    -   **Report**:
        -   Consolidate findings into a Markdown report.
        -   Include actionable steps for installation if "GO".
        -   Return JSON: `{"report": "..."}`.

3.  **Finalize Pulse**:
    -   Update `last_run` timestamp.
    -   Set status back to "idle".
    -   Write state back to `skills/cron-nvidia-kernel-audit/state.json`.

## Historical Failures Context

### Known Failure Scenarios
-   **Kernel 6.17.0-22-generic / 6.17.0-14-generic**: Resulted in hard freezes/black screens even with NVIDIA drivers (535+) building correctly.
-   **Primary Symptoms**: Hard freeze at black screen (likely DRM/Modeset failure) or Kernel Panic (Unable to mount root fs).
-   **Previous Blockers**:
    -   `virtualbox-dkms` conflicts during kernel installation, leading to "Half-configured" (iF) states.
    -   Missing `nvidia-drm.modeset=1` kernel parameter, critical for Wayland/Hyprland.
-   **Current Stable Base**: 6.14.0-37-generic.

### Resolution Steps from Past Audits
-   Ensure `/boot` has sufficient space for `initrd` generation.
-   Manually rebuilding `initramfs` if missing: `update-initramfs -c -k <version>`.
-   Purging conflicting modules like `virtualbox-dkms`.
-   Ensuring `nvidia-drm.modeset=1` is in `/etc/default/grub`.

## Logic & Workflow

1.  **Context**: Utilizes embedded **Historical Failures Context** to evaluate current safety reports.
2.  **Web Fetching**: Uses `connectivity-expert` and web search tools (Exa, Brave) for current reports.
3.  **Output Hygiene**: Adheres to the standard cron output format (plain Markdown, bullet-point lists, no JSON envelopes, no tables).

## Instructions

- You are a specialized **Kernel Safety Auditor** for the `cron-nvidia-kernel-audit` skill.
- **Goal**: Provide a clear "GO" or "NO-GO" recommendation for kernel upgrades.
- **Precedence**: The embedded **Historical Failures Context** takes precedence over general web advice.
- **Reporting**: Always include an "Actionable Steps" section in the report if a fix is identified.

## Reporting Protocol
This skill MUST output its final results directly to stdout for external handling and MUST NOT use the to-discord command for automated reporting.