---
name: update-anime-list
description: Automates the identification and updating of entries in an anime tracking list, including filing finished series.
---

# Role: Anime Library Automation Agent

# Objective: Synchronize the local anime collection with global release status and automate missing episode downloads.

## 0. Path Resolution
- **Towatch Folder:** The skill MUST run with the current directory (`pwd`) set to the anime year folder to watch (e.g. `.../towatch/anime/2026`). All scanning and JSON operations happen inside `pwd`. Never hardcode the drive mount path.
- **Definitive Folder:** Walk up from `pwd` one directory at a time until a directory containing both a `towatch` and an `Anime` child directory is found (the external drive root). The definitive folder is `<drive root>/Anime`. If no such root is found, ask the user for the definitive folder path.

## Dynamic Nushell Scripting & Local Context Protocols
Whenever the agent identifies that a Nushell pipeline or logic sequence will be used frequently or has non-trivial complexity (such as directory scanning, video file/repeated episode counting, JSON sync/sanitization, Transmission queue status verification, or copy-verify-delete filing), it is empowered and encouraged to create or update a `scripts/` directory directly within the current working directory (`<pwd>/scripts/`):

1. **Script Architecture & Modularity:**
   - Organize scripts as reusable Nushell modules (e.g., `scripts/anime_utils.nu` or domain-specific `.nu` files) designed to be loaded via `use scripts/<file>.nu *`.
   - All functions intended for execution must be exported using `export def`.
   - Private helpers (if any) should be unexported at the bottom of the file or prefixed with `_`.

2. **Conductor Nushell Styleguide Compliance (`/home/username/workspace/my_scripts/nushell/conductor`):**
   - **Type Signatures:** Mandatory parameter and return type signatures for all public commands (e.g. `export def scan-episodes [folder: string]: nothing -> table { ... }`).
   - **Docstrings:** Preceding comment block on every `export def` documenting purpose, parameters, and return type.
   - **Structured Data:** Always return structured data (Tables, Records, Lists) rather than unformatted text strings.
   - **Pure Nushell Priority:** Rely on native Nushell commands (`lines`, `split row`, `where`, `select`, `parse -r`, `get -o`, `try/catch`) rather than legacy shell tools (`grep`, `awk`, `sed`) or external Python scripts.
   - **ANSI Stripping:** Use `ansi strip` when parsing outputs containing terminal color codes (e.g., `t list` output).
   - **Dynamic Paths:** Never hardcode absolute external drive roots; use `pwd`, relative paths, or dynamic path resolution.

3. **Working Directory Context Synchronization (`GEMINI.md`, `CLAUDE.md`, `AGENTS.md`):**
   - Whenever `.nu` script files are created or modified in `<pwd>/scripts/`, create or update `GEMINI.md`, `CLAUDE.md`, and `AGENTS.md` directly within `<pwd>`.
   - The context files must contain:
     - Clear description of each available command and its signature.
     - Concrete examples of how to load and invoke them (`use scripts/<file>.nu *`).
     - Clear operational context describing when and during which workflow phase to execute each command.

## 1. Local Library Audit
- **Scan Subdirectories:** Identify all folders in the current directory (`pwd`).
- **Exclusions:** Strictly ignore: `Completed`, `Movies`, `MoviesOvas`, and hidden folders (starting with `.`).
- **Episode Counting:** For each folder, list and count the files with video extensions (`.mkv`, `.mp4`, `.avi`, `.webm`). Detect repeated episodes and count them separately. The actual count of episodes is the `downloaded_episodes`. Report repeated episodes at the final report. An exception rule for `One Piece`: only consider episodes released in the year of the folder (anime will be inside a folder called YYYY, for instance 2026) so for One Piece in folder YYYY, only consider episodes released during year YYYY.
- **Sync Status:** Load `anime_status.json`. If it doesn't exist, initialize it as an empty array `[]`.
- **New Entries:** For any local folder with no corresponding JSON entry, create a new entry (with `full_name` defaulting to the folder name and `total_episodes`/`released_episodes`/`finished` filled by the Global Status Synchronization step below) and **ask the user for its `watching` value at that moment** before saving.
- **erai.txt Filter Keyword (new series only):** For each NEW entry, derive ONE relevant keyword — a distinctive substring of the official `full_name` that Erai-raws torrent names actually contain (skip generic words like `The`, `no`, `wa`, `san`). Append it to the whitelist used by `t filter-anime` (`[$env.MY_ENV_VARS.linux_backup erai.txt] | path join`, i.e. `/home/username/workspace/Backups/linux/erai.txt`), deduped case-insensitively (never add a word already present in any case):
    ```nu
    let existing = open --raw ([$env.MY_ENV_VARS.linux_backup erai.txt] | path join) | lines | str lowercase
    let kw1 = ($kw | str trim | split row " " | first | str trim)
    if ($kw1 | str lowercase) not-in $existing {
        $kw1 | save -a ([$env.MY_ENV_VARS.linux_backup erai.txt] | path join)
    }
    ```
  Then commit `erai.txt` in the Backups/linux repo (`^git -C /home/username/workspace/Backups/linux add erai.txt` + `commit -m "chore(anime): add filter keyword '<kw>' to erai.txt"`).
- **Clean-up:** Remove any entries from the JSON where the corresponding local directory no longer exists.
- **Helper Scripting:** The agent may extract and maintain these scanning, episode counting, and JSON audit routines inside `<pwd>/scripts/anime_utils.nu`.

## 2. Global Status Synchronization
- **WEBSEARCH:** Activate the `nushell-expert` skill, then use nushell command `askai -GOw` via the evaluate tool of the nushell mcp server to do websearch. In case of issues, fallback to activating the `connectivity-expert` skill to learn the protocols for websearch. NOTE that `askai -GOw` can address multiple questions in a single request, so it's more efficient than making separate requests for each anime.
- **Metadata Search:** For each local anime folder, search the web (MyAnimeList, AniList, etc.) to get the most accurate current data.
- **Normalization:** Clean directory names (remove year tags, studio names, or quality markers) before searching to ensure high-fidelity matches.
- **Data Points:**
    - `full_name`: The official series title (resolve shortcut/romanized folder names to the official title).
    - `total_episodes`: The total number of planned episodes for the season/series.
    - `released_episodes`: The number of episodes released globally to date.
    - `finished`: A boolean indicating if the series has concluded (all planned episodes are released).
- **Update JSON:** Save the results to `anime_status.json` following this schema:
    ```json
    [
      {
        "anime_name": "Folder Name",
        "full_name": "Official Series Title",
        "total_episodes": 0,
        "released_episodes": 0,
        "downloaded_episodes": 0,
        "finished": false,
        "watching": true
      }
    ]
    ```

## 3. Torrent Retrieval (Gap Filling)
- **Identify Missing:** If `downloaded_episodes` < `released_episodes`, identify the missing episode numbers. This identification must be done via listing the files (via `ls`).
- **Torrent Fetching:** For each missing episode, attempt to download the torrent:
    - **Primary URL:** `https://nyaa.si/user/Erai-raws?f=0&c=0_0&q=[Anime Name]` (URL-encoded).
    - **Target Quality:** Download the **720p multisub** version.
    - **Destination:** Save `.torrent` files to `~/cloud/Aplicaciones/Gmail`.
- **Transmission Verification (mandatory):** The watch folder (`~/cloud/Aplicaciones/Gmail`) is monitored by `transmission-daemon`, which automatically adds new torrents to the queue and **deletes the `.torrent` file** once picked up. A missing `.torrent` file is therefore expected behavior, NOT an error — never fail or warn because of it. After downloading the torrents for the current batch:
    1. Activate the `nushell-expert` skill (if not already active).
    2. Run `t list` once via the nushell evaluate tool to get the current Transmission queue.
    3. Parse the output: for each downloaded episode, check whether its expected filename pattern (e.g. `[Erai-raws] <Anime Name> - <Episode>`) appears in the `Name` column. The `Name` column contains ANSI color codes, so apply `ansi strip` before matching:
        ```nu
        let expected = ["[Erai-raws] Degarashi Ouji - 07", "[Erai-raws] tenbin - 07"]
        let watch_files = (glob $"($env.HOME)/cloud/Aplicaciones/Gmail/*.torrent" | str join "\n")
        let transmission_names = t list | get Name | ansi strip | str join "\n"
        $expected | each { |ep|
          let found = ($transmission_names | str contains -i $ep)
          let file_still_present = ($watch_files | str contains -i $"($ep).torrent")
          { episode: $ep, status: (if $found { "queued" } else if $file_still_present { "pending" } else { "failed" }) }
        }
        ```
    4. Classify each downloaded torrent:
        - **Found in `t list`** → report as "Successfully queued in Transmission" (success, regardless of `.torrent` file presence).
        - **Not found in `t list` AND `.torrent` file still present** → report as "Torrent file saved, awaiting Transmission pickup" (pending, not a failure).
        - **Not found in `t list` AND `.torrent` file missing** → report as "Download failed — manual intervention required" and output the direct search URL.
- **Helper Scripting:** The agent may extract and maintain the Transmission verification logic inside `<pwd>/scripts/anime_utils.nu`.
- **Fallbacks:**
    - If the direct search fails, check the RSS feed: `https://nyaa.si/?page=rss&c=0_0&f=0&u=Erai-raws`.
    - If automated download is not possible, output the direct search URL clearly for manual access.

## 4. Filing Completed Series
After synchronization, determine for each entry whether the series is **complete**: `finished == true` AND `downloaded_episodes >= total_episodes`. If `total_episodes` is `null`, treat `released_episodes` as the target (i.e. complete when `downloaded_episodes >= released_episodes`).

For each complete series, file its folder based on `watching`:
- **`watching == false`** → move the folder to `<pwd>/Completed`.
- **`watching == true`** → move the folder to `<definitive>/<year>`, where `<year>` is the basename of `pwd` (e.g. `<drive root>/Anime/2026`). If a folder with the same name already exists in the target, skip the move and report it as a potential duplicate.

**Safety Protocol (mandatory):**
1. **Create target directories first** if they do not exist (`mkdir` the `Completed` folder or the definitive year folder).
2. **Copy first:** copy the whole folder to the target (`cp -r`).
3. **Verify before deleting:** compare the copy against the source — same file count and same total byte size (e.g. via `ls`/`du`). Only if they match, **delete the source** (`rm -r`). If verification fails, keep the source and report the failure.
- Incomplete or ongoing series (`finished == false`, or `downloaded_episodes < total_episodes`) are never moved.
- **Helper Scripting:** The agent may extract and maintain the copy-verify-delete routines inside `<pwd>/scripts/anime_utils.nu`.

## 5. Execution Report
Provide a concise summary of the actions taken:
- Entries removed due to missing directories.
- Entries updated with new episode counts or finished status.
- New entries added (with the `watching` value provided by the user).
- `erai.txt` keywords appended: one per new series (`<kw>` with its `full_name`).
- Series filed to `Completed` or the definitive folder (with verification results).
- Specific torrents successfully queued in Transmission (with the status classification: queued / awaiting pickup / failed with manual URL).
- URLs provided for manual download where automation failed.
- Helper scripts created or updated in `<pwd>/scripts/` along with context documentation (`GEMINI.md`, `CLAUDE.md`, `AGENTS.md`) in `<pwd>`.