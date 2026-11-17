---
name: cron-anime-download-checker
description: Autonomous cron skill to audit anime episode availability across offline media database, local downloads, and Transmission queue, identify missing release gaps, and download .torrent files to the watch directory.
---

# cron-anime-download-checker

Autonomous cron skill for auditing anime episode availability, detecting missing release gaps against Nyaa Erai-raws, and automating `.torrent` file downloads into Transmission's watch folder. Operates seamlessly even when external hard drives are physically disconnected by querying the in-memory offline media database catalog and official airing APIs (AniList & Jikan).

## Nushell Execution Protocol

**CRITICAL: All Nushell commands MUST be executed via the `standard-nushell_evaluate` MCP tool.**

Use the `evaluate` tool with the `input` parameter set to the Nushell code shown in each step.

**Fallback (only if the `evaluate` tool is unavailable):**
```bash
nu -c '<nushell_code>'
```

**CRITICAL: Never use the `to-discord` nushell command. Do not send any Discord notifications during automated cron runs.**

**ALWAYS activate the `nushell-expert` skill before the first Nushell command.**

## Storage Tiers Architecture

To determine acquired episodes without requiring external storage mounts, the skill audits three storage tiers:

1. **Tier 1 (Offline External Hard Drives via In-Memory Media Database Catalog):**
   - **Snapshot Deduplication:** Scans `*.json` files in `$env.MY_ENV_VARS.media_database`, sorts by `modified` descending, and retains only the newest snapshot per drive `location` so relocated series in stale snapshots do not re-appear as active candidates.
   - **Candidate Discovery & Sub-Arc Title Resolution:** Candidate folders are strictly scoped to `towatch/anime/<current_year>/<folder>` (excluding `Completed/`, `MoviesOvas/`, scripts, and hidden directories). For each active folder, inspects filenames inside `towatch/anime/<current_year>/<folder>` and resolves the predominant release series title (e.g., `Tokyo Revengers - Santen Sensou Hen` instead of bare `Tokyo Revengers`), excluding any series/folders present in `Completed/`.
   - **Season-Scoped Episode Auditing:** Uses strict `series-title-matches` comparison (normalized exact match or explicit sub-arc suffix match) instead of broad substring/regex matching so prior seasons (e.g., `Tougen Anki` from 2025) never pollute sub-arc episode counts (`Tougen Anki - Nikko Kegon no Taki-hen`). Also avoids regex-metacharacter bugs on titles with parentheses such as `(2026)`.
   - *Special Rule (One Piece):* Only counts episodes released in the target year.

2. **Tier 2 (Local Completed Downloads):**
   - Scans `~/Downloads/Torrent`.
   - Parses video files matching multi-subgroup releases `[<Subgroup>] <Series> - <Ep> ...` (e.g., `[Erai-raws]`, `[PuyaSubs!]`, `[CameEsp]`, `[A-Kei]`), including `END` and `v2` suffixes.

3. **Tier 3 (Active Transmission Queue):**
   - Directly inspects `transmission-remote -l` without subshell overhead.
   - Captures torrents currently downloading, queuing, or seeding.
   - **Automatic Cross-Subgroup Redundancy Purge:** Automatically purges torrents from Transmission via `purge-redundant-torrents` (`transmission-remote -rad`) if their corresponding `<series, episode>` already exists on external storage drives, even under a different subgroup tag or streaming provider tag (e.g., `[Erai-raws]` torrent vs `[PuyaSubs!]` on external drive).

## Video Profile & Airing Status Resolution

1. **Majority-Vote Video Profile Resolution:**
   - Counts existing acquired `1080p` vs `720p` files and selects `1080p` only when `cnt_1080p > cnt_720p`; similarly selects `HEVC` only when `cnt_hevc > cnt_avc` (and filters Nyaa items strictly by both profile and `series-title-matches`).
   - Ensures downloads match the existing series profile. Defaults to `720p AVC` for new series.

2. **Official Airing Verification (AniList & Jikan):**
   - Queries AniList GraphQL API (`https://graphql.anilist.co`) for current airing status and episode count, with Jikan v4 fallback (`https://api.jikan.moe/v4/anime`).
   - If the latest officially aired episode <= acquired episodes, the series is marked `UP TO DATE` and skips Nyaa queries.

## Logic & Workflow

### Step 1: Environment & Engine Initialization
Execute via `evaluate` tool:
```nu
use ~/workspace/llms_configs/skills/cron-anime-download-checker/scripts/anime_checker.nu *
```

### Step 2: Run Full Download Audit & Gap Resolution
Execute via `evaluate` tool:
```nu
run-anime-check
```

The engine autonomously:
1. Purges redundant torrents from Transmission that already exist in the external media database.
2. Discovers all active candidate anime series from Tier 1 (airing in current year), Tier 2, and Tier 3.
3. Resolves the series video profile (resolution & codec) from existing files.
4. Queries official airing counts via AniList/Jikan to gate unnecessary web queries.
5. If missing episodes are detected, queries Nyaa Erai-raws RSS matching the target profile.
6. Identifies gaps: `Released on Nyaa` - `(Tier 1 ∪ Tier 2 ∪ Tier 3)`.
7. For each missing episode gap, downloads the `.torrent` file directly into `~/cloud/Aplicaciones/Gmail`.
8. Audits Transmission pickup status via `transmission-remote` and outputs verification results.

## Output Format (MANDATORY)

- Output directly to `stdout` as clean Markdown.
- Use bullet-point lists (`- `) for all summary and series items.
- NEVER output raw JSON, HTML dumps, or markdown tables.
- Example structure:
  ```markdown
  # Anime Download Audit: YYYY-MM-DD HH:MM
  - Discovered 14 candidate series.
  - Romelia Senki: 6 acquired, 6 released — UP TO DATE
  - Hotaru no Yomeiri: MISSING EPISODES: 06
    • Downloaded torrent for episode 6: 2183365.torrent
  
  ## Transmission Pickup Verification
  - [Erai-raws] Hotaru no Yomeiri - 6: queued
  ```

## Crontab Schedule Reference

Configured on the host machine to run daily at 1:00 AM:
```cron
0 1 * * * nu --config /home/username/.config/nushell/config.nu --env-config /home/username/.config/nushell/env.nu -c "opn cron cron-anime-download-checker -bm opencode/deepseek-v4.1-flash-free"
```
