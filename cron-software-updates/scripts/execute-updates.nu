#!/usr/bin/env nu

# Executes update commands from this_machine.json.
# Reads each entry, runs the update_command, and collects failures into errors.json.
# --json-file: path to this_machine.json (defaults to skill_dir/this_machine.json)
def main [--json-file: string] {
    let skill_dir = "/home/username/workspace/llms_configs/skills/cron-software-updates"
    let input_file = if ($json_file | is-empty) {
        $"($skill_dir)/this_machine.json"
    } else {
        $json_file
    }

    if not ($input_file | path exists) {
        print $"(ansi red)Error:(ansi reset) this_machine.json not found at ($input_file)"
        exit 1
    }

    let entries = open $input_file
    mut errors = []
    mut successes = []

    for entry in $entries {
        let cmd = $entry.update_command
        if (($entry.name | str lowercase) =~ "nushell" or ($cmd | str lowercase) =~ "apps-update nushell") {
            print $"Skipping ($entry.name) — managed via nushell-update-evaluator (ansi yellow)SKIPPED(ansi reset)"
            continue
        }
        print $"Updating ($entry.name)..."
        let result = try {
            nu --config ~/.config/nushell/config.nu --env-config ~/.config/nushell/env.nu -c $cmd | complete
        } catch { |err|
            { exit_code: 1, stderr: $"Failed to spawn: ($err.msg)" }
        }

        if $result.exit_code == 0 {
            print $"  (ansi green)OK(ansi reset)"
            $successes = ($successes | append $entry.name)
        } else {
            print $"  (ansi red)FAILED(ansi reset): ($result.stderr | str trim)"
            $errors = ($errors | append [{
                name: $entry.name,
                update_command: $cmd,
                error: ($result.stderr | str trim),
                todos_id: $entry.todos_id
            }])
        }
    }

    if ($successes | length) > 0 {
        print $"\n(ansi green)Successfully updated: ($successes | str join ', ')(ansi reset)"
    }

    if ($errors | length) > 0 {
        let errors_file = $"($skill_dir)/errors.json"
        $errors | to json | save -f $errors_file
        print $"\n(ansi yellow)($errors | length) updates failed. Errors saved to (ansi reset)($errors_file)"
    } else {
        print $"\n(ansi green)All updates completed successfully.(ansi reset)"
        let errors_file = $"($skill_dir)/errors.json"
        [] | to json | save -f $errors_file
    }
}
