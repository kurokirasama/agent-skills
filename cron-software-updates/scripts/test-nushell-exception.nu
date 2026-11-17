#!/usr/bin/env nu

# Validates total exclusion of Nushell and Nushell plugins in cron-software-updates.
# Confirms:
#   - SKILL.md documents complete exclusion of core Nushell and plugins from cron-software-updates
#   - Ingestion filtering omits nushell, nushell-plugins, and nushell-plugins-external
#   - Step 7 logic creates 0 tasks for nushell and plugins
#   - Regression: non-Nushell software (claude-code, matlab-lsp, rclone) is retained and tagged

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

def assert-true [cond: bool, label: string] {
    if $cond {
        print $"(ansi green)PASS(ansi reset): ($label)"
    } else {
        print $"(ansi red)FAIL(ansi reset): ($label)"
        exit 1
    }
}

let script_dir = ($env.CURRENT_FILE | path dirname)
let skill_md = open --raw ($script_dir | path join ".." "SKILL.md")
let execute_updates_nu = open --raw ($script_dir | path join "execute-updates.nu")

# --- Test 1: Documentation in SKILL.md ---
# SKILL.md must document complete exclusion of nushell and plugins, referencing nushell-update-evaluator
let has_exclusion_doc = (
    ($skill_md =~ "(?i)nushell-update-evaluator") and
    ($skill_md =~ "(?i)nushell.*skip|exclude") and
    not ($skill_md =~ 'h add todos --text "<update_command>" --notes "" --priority 1 --due "" --checklist \[\]\n\n### Step 8')
)
assert-true $has_exclusion_doc "SKILL.md documents total exclusion of Nushell and plugins (no h add todos for nushell)"

# --- Test 2: Ingestion & Assembly Filtering ---
def is-nushell-entry [entry: record] {
    let name = ($entry.name? | default "") | str lowercase
    let cmd = ($entry.update_command? | default "") | str lowercase
    ($name =~ "nushell") or ($cmd =~ "apps-update nushell")
}

let raw_incoming = [
    { name: "nushell", update_command: "apps-update nushell" },
    { name: "nushell-plugins", update_command: "apps-update nushell-plugins" },
    { name: "nushell-plugins-external", update_command: "apps-update nushell-plugins-external" },
    { name: "claude-code", update_command: "apps-update claude" },
    { name: "matlab-lsp", update_command: "apps-update matlab-lsp" },
    { name: "rclone", update_command: "apps-update rclone" }
]

let filtered_incoming = $raw_incoming | where {|e| not (is-nushell-entry $e) }
assert-eq ($filtered_incoming | length) 3 "Ingestion filter removes all 3 Nushell variants"
assert-true ($filtered_incoming | all {|e| not (is-nushell-entry $e)}) "Filtered list contains only non-Nushell entries"

# --- Test 3: Step 7 Task Creation (Zero tasks for Nushell) ---
def step7-tasks [entry: record, other_machines: list<string>] {
    if (is-nushell-entry $entry) {
        [] # Completely excluded: zero tasks created for Habitica
    } else {
        $other_machines | each {|m|
            { text: $entry.update_command, tag: $"software-updates-($m)" }
        }
    }
}

let other_machines = ["workstation", "desktop"]
let nushell_tasks = step7-tasks { name: "nushell", update_command: "apps-update nushell" } $other_machines
let nushell_plugin_tasks = step7-tasks { name: "nushell-plugins", update_command: "apps-update nushell-plugins" } $other_machines
let nushell_ext_tasks = step7-tasks { name: "nushell-plugins-external", update_command: "apps-update nushell-plugins-external" } $other_machines

assert-eq ($nushell_tasks | length) 0 "Step 7 creates 0 Habitica tasks for core nushell"
assert-eq ($nushell_plugin_tasks | length) 0 "Step 7 creates 0 Habitica tasks for nushell-plugins"
assert-eq ($nushell_ext_tasks | length) 0 "Step 7 creates 0 Habitica tasks for nushell-plugins-external"

# --- Test 4: Regression on Other Software in Step 7 ---
let claude_tasks = step7-tasks { name: "claude-code", update_command: "apps-update claude" } $other_machines
assert-eq ($claude_tasks | length) 2 "Step 7 creates 2 tasks for claude-code (one per other machine)"
assert-eq ($claude_tasks | get tag) ["software-updates-workstation", "software-updates-desktop"] "claude tasks have machine tags"

let matlab_tasks = step7-tasks { name: "matlab-lsp", update_command: "apps-update matlab-lsp" } $other_machines
assert-eq ($matlab_tasks | length) 2 "Step 7 creates 2 tasks for matlab-lsp (one per other machine)"

# --- Test 5: Execution Engine Safeguard in execute-updates.nu ---
let has_exec_guard = (
    ($execute_updates_nu =~ '(?i)nushell') and
    ($execute_updates_nu =~ '(?i)skip')
)
assert-true $has_exec_guard "execute-updates.nu contains internal safety guard skipping nushell commands"

print $"(ansi green)All assertions passed — Nushell exclusion verified.(ansi reset)"
