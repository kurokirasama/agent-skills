# BUG-02 fix: Nushell `source` and `use` require parse-time constants (no runtime expressions).
# We use relative paths which resolve relative to the directory containing this script.
source ./report_failure.nu
use ./status.nu get-status

def main [--root: string, --dry_run, --force_fail, --report, --json-file: string] {
    try {
        if $force_fail {
            error make { msg: "FORCED_FAILURE_FOR_TESTING" }
        }
        let script_dir = $env.CURRENT_FILE? | default "" | path dirname
        let script_dir = if ($script_dir | is-empty) {
            if ("skills/cron-conductor-monitor/scripts" | path exists) {
                "skills/cron-conductor-monitor/scripts" | path expand
            } else {
                let llms = try { $env.MY_ENV_VARS.llms_configs } catch { "~/llms_configs" } | path expand
                [$llms "skills" "cron-conductor-monitor" "scripts"] | path join | path expand
            }
        } else {
            $script_dir
        }
        let discover_script = [$script_dir "discover.nu"] | path join

        let json_file = if ($json_file | is-not-empty) {
            $json_file | path expand
        } else if ($root | is-empty) {
            [$script_dir "conductor_projects.json"] | path join
        } else {
            ""
        }

        mut project_data = []

        if ($json_file | path exists) {
            let projects = nu $discover_script --json-file $json_file | lines
            if ($projects | is-not-empty) {
                let data = $projects
                    | each { |p|
                        try {
                            get-status $p ($p | path dirname | path dirname)
                        } catch {
                            print $"Warning: Failed to parse status for project ($p)"
                            null
                        }
                    }
                    | where { |proj| $proj != null }
                $project_data = ($project_data | append $data)
            }
        } else if ($root | is-not-empty) {
            # Fallback: legacy glob-based discovery
            let roots = [ $root ]
            for r in $roots {
                let expanded_r = $r | path expand
                if ($expanded_r | path exists) {
                    let projects = nu $discover_script $expanded_r | lines
                    if ($projects | is-not-empty) {
                        let data = $projects
                            | each { |p|
                                try {
                                    get-status $p $expanded_r
                                } catch {
                                    print $"Warning: Failed to parse status for project ($p)"
                                    null
                                }
                            }
                            | where { |proj| $proj != null }
                        $project_data = ($project_data | append $data)
                    }
                }
            }
        }
        
        if ($project_data | is-empty) {
            print "No pending work found."
            return
        }
        
        # Hierarchical grouping by Folder -> Project
        let folders = $project_data | group-by folder
        
        let date = date now | format date "%Y-%m-%d %H:%M:%S"
        mut report_md = $"# Conductor Monitor Report - ($date)\n\n"

        for folder_name in ($folders | columns) {
            $report_md = ($report_md + $"## Folder: ($folder_name)\n\n")
            
            let projects_in_folder = $folders | get $folder_name
            for project_info in $projects_in_folder {
                let name = $project_info.project
                let path = $project_info.path
                let tracks = $project_info.tracks
                let todos = $project_info.todos
                
                $report_md = ($report_md + $"### Project: ($name)\n")
                $report_md = ($report_md + $"*Path: `($path)`*\n\n")
                
                if ($tracks | is-not-empty) {
                    $report_md = ($report_md + "**Pending Tracks:**\n")
                    for t in $tracks {
                        $report_md = ($report_md + $"- [($t.status)] ($t.title) - ID: ($t.id)\n")
                    }
                    $report_md = ($report_md + "\n")
                }
                
                if ($todos | is-not-empty) {
                    $report_md = ($report_md + "**Pending Todos:**\n")
                    for todo in $todos {
                        $report_md = ($report_md + $"- [ ] ($todo)\n")
                    }
                    $report_md = ($report_md + "\n")
                }
                
                $report_md = ($report_md + "\n")
            }
        }
        
        if $report {
            if $dry_run {
                # BUG-04 fix: show actual report_md in dry-run mode, not a useless literal string
                print $"[DRY RUN] Would output the following report:\n($report_md)"
            }
        }

        print $report_md
        
    } catch { |err|
        let action = report_failure "cron-conductor-monitor" $err.msg "N/A" "Medium"
        print $action
        error make { msg: $err.msg }
    }
}