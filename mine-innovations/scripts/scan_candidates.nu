#!/usr/bin/env nu

# mine-innovations-scan.nu
# Scans Conductor archives and Git history for potential innovation candidates.

def main [] {
    let archives = ls conductor/archive/ | each { |f| 
        {
            path: $f.name,
            type: "archive",
            last_modified: $f.modified
        }
    }

    let tracks = ls conductor/tracks/ | each { |f| 
        {
            path: $f.name,
            type: "track",
            last_modified: $f.modified
        }
    }

    # Get recent Git commits related to Conductor tracks
    let commits = git log --grep="conductor" --oneline -n 20 | lines | each { |l|
        let parts = $l | split row " "
        {
            sha: $parts.0,
            subject: ($parts | skip 1 | str join " "),
            type: "git"
        }
    }

    {
        archives: $archives,
        tracks: $tracks,
        commits: $commits
    } | to json
}