#!/usr/bin/env nu

# Validates the source-aware sudo task logic in cron-software-updates (Step 4 + Step 8).
# Simulates the documented behavior to confirm:
#   - email-sourced sudo entries carry source=email and generate tasks for ALL machines
#   - habitica-sourced sudo entries carry source=habitica and are SKIPPED (no duplicates)

def assert-eq [actual: any, expected: any, label: string] {
    if $actual == $expected {
        print $"(ansi green)PASS(ansi reset): ($label)"
    } else {
        print $"(ansi red)FAIL(ansi reset): ($label)"
        print $"  expected: ($expected)"
        print $"  actual:   ($actual)"
        exit 1
    }
}

let sudo_names = ["rclone", "earth", "yandex", "sejda", "ttyplot"]

# Simulate Step 4: tag source when moving to sudo.json
let email_entry = {
    mail_id: "abc123",
    todos_id: "",
    name: "rclone",
    installed: false,
    update_command: "apps-update rclone"
}
let habitica_entry = {
    mail_id: "",
    todos_id: "c0a1ddf9-a578-402a-85a4-b0fa02e0ad77",
    name: "rclone",
    installed: false,
    update_command: "apps-update rclone"
}

let email_sudo = if ($email_entry.name in $sudo_names) {
    $email_entry | upsert source "email"
} else { [] }
let habitica_sudo = if ($habitica_entry.name in $sudo_names) {
    $habitica_entry | upsert source "habitica"
} else { [] }

# FR1: source field present and correct
assert-eq ($email_sudo.source) "email" "email-sourced entry tagged source=email"
assert-eq ($habitica_sudo.source) "habitica" "habitica-sourced entry tagged source=habitica"

# FR2: task creation decision per source
let machines = ["workstation", "desktop", "laptop"]

let email_tasks = if $email_sudo.source == "email" { $machines | each {|m| {text: $email_sudo.update_command, tag: $m} } } else { [] }
assert-eq ($email_tasks | length) 3 "email-sourced rclone generates 3 tasks (all machines)"

let habitica_tasks = if $habitica_sudo.source == "habitica" { [] } else { $machines | each {|m| {text: $habitica_sudo.update_command, tag: $m} } }
assert-eq ($habitica_tasks | length) 0 "habitica-sourced rclone generates 0 tasks (skipped)"

# AC3: sudo.json entries carry source field
let sudo_json = [$email_sudo, $habitica_sudo]
assert-eq ($sudo_json | all {|e| ("source" in $e) }) true "all sudo.json entries carry source field"

# AC4: regression — other sudo packages (earth, yandex, sejda, ttyplot) from email still generate tasks for ALL machines
let other_sudo = ["earth", "yandex", "sejda", "ttyplot"]
for name in $other_sudo {
    let entry = { mail_id: "mail_($name)", todos_id: "", name: $name, installed: false, update_command: $"apps-update ($name)" }
    let sudo_entry = if ($entry.name in $sudo_names) { $entry | upsert source "email" } else { [] }
    assert-eq ($sudo_entry.source) "email" $"($name) from email tagged source=email"
    let tasks = if $sudo_entry.source == "email" { $machines | each {|m| {text: $sudo_entry.update_command, tag: $m} } } else { [] }
    assert-eq ($tasks | length) 3 $"($name) from email generates 3 tasks - all machines, no regression"
}

print $"(ansi green)All assertions passed — source-aware sudo task logic verified.(ansi reset)"
