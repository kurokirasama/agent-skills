# skills/longterm-skillopt-optimizer/mod.nu

use /home/username/workspace/llms_configs/skills/longterm-memory-reader/mod.nu [get-vault find-project-root parse-frontmatter get-body]
export use /home/username/workspace/llms_configs/skills/longterm-skillopt-optimizer/scripts/optimizer_utils.nu [parse-trajectory-failures load-rejected-buffer process-drafts]

# Core function to execute the weekly SkillOpt optimization loop
export def process-skillopt-logs [project_path: path, --vault: path]: nothing -> nothing {
    let vault_path = $vault | default (get-vault)
    
    # 1. Process pending drafts (Approve / Reject)
    print "Processing pending skill improvement drafts..."
    let approved_plans = process-drafts $project_path --vault $vault_path

    # 1.5 Scan for new drafts and create Habitica todos
    let draft_dir = [$vault_path "AGENTS_MEMORY" "_draft_improvements"] | path join
    if ($draft_dir | path exists) {
        let drafts = glob ([$draft_dir "*.md"] | path join)
        for draft in $drafts {
            let content = open --raw $draft
            let fm = parse-frontmatter $content
            if $fm == null { continue }

            let implemented = try { $fm.implemented } catch { false }
            let todo_created = try { $fm.habitica_todo } catch { false }

            if (not $implemented) and (not $todo_created) {
                # New draft! Let's collect targets
                let chunks = $content | split row "### " | skip 1
                mut targets = []
                for chunk in $chunks {
                    let lines = $chunk | lines
                    if ($lines | is-empty) { continue }
                    let header = $lines | get 0
                    let parsed_skill = $header | parse --regex '`(?P<name>.*?)`'
                    if not ($parsed_skill | is-empty) {
                        $targets = ($targets | append $parsed_skill.0.name)
                    }
                }

                if not ($targets | is-empty) {
                    let has_gemini_bak = "gemini-bak.md" in $targets
                    let todo_text = if $has_gemini_bak {
                        "new gemini-bak.md draft improvement available"
                    } else {
                        "new skill draft improvement available"
                    }

                    # Create the habitica todo
                    print $"Creating Habitica todo: ($todo_text) with checklist ($targets)"
                    let payload = h add todos --text $todo_text --priority 1.0 --notes "" --due "" --checklist $targets --dry-run

                    # Update frontmatter of the draft file to set habitica_todo: true
                    let new_fm = $fm | insert habitica_todo true
                    let fm_yaml = $new_fm | to yaml
                    let body = get-body $content
                    let new_content = $"---
($fm_yaml)---
($body)"
                    $new_content | save -f $draft
                }
            }
        }
    }

    # 2. Scan recent trajectory logs for events/failures
    print "Scanning trajectory logs for events..."
    let events = parse-trajectory-failures $project_path --vault $vault_path
    
    if ($events | is-empty) and ($approved_plans | is-empty) {
        print "No trajectory events or approved plans found. Skill optimization not required."
        return
    }
    
    # 3. Load active custom skills and their contents
    let skills_dir = [$project_path "skills"] | path join
    if not ($skills_dir | path exists) {
        print $"Skills directory ($skills_dir) does not exist."
        return
    }
    
    let skill_folders = ls $skills_dir | where type == dir | get name
    let active_skill_names = $skill_folders | each { |f| $f | path basename }
    let skills_str = $active_skill_names | str join ", "
    
    # 4. Load trajectory events log context
    let events_str = $events | each { |f|
        $"Skill: ($f.skill)\nType: ($f.type)\nEvent: ($f.event)\nStatus: ($f.status)\nOutput: ($f.output)\nSource log: ($f.file | path basename)\n"
    } | str join "\n"
    
    # 5. Load rejected improvements buffer
    let rejected_str = load-rejected-buffer --vault $vault_path
    
    # Print structured information for the agent to consume
    print "\n=== SKILLOPT OPTIMIZATION CONTEXT ==="
    print "\n--- RECENT TRAJECTORY EVENTS ---"
    if ($events_str | is-empty) {
        print "No recent failures or workflow issues found."
    } else {
        print $events_str
    }
    print "\n--- APPROVED PLANS TO MANUALLY IMPLEMENT ---"
    if ($approved_plans | is-empty) {
        print "No approved plans to implement."
    } else {
        for plan in $approved_plans {
            print $"Draft File: ($plan.draft_file)"
            print $"Skill: ($plan.skill)"
            print $"File: ($plan.file)"
            print "Patches:"
            print $plan.patches
            print "------------------------"
        }
    }
    print "\n--- REJECTED IMPROVEMENTS BUFFER ---"
    if ($rejected_str | is-empty) {
        print "No rejected improvements in buffer."
    } else {
        print $rejected_str
    }
    let gemini_bak_path = [$project_path "gemini-bak.md"] | path join
    if ($gemini_bak_path | path exists) {
        print "\n=== GEMINI-BAK GUIDELINES ==="
        print "(gemini-bak.md exists; read on-demand for relevant sections)"
    }

    print "\n--- ACTIVE CUSTOM SKILLS ---"
    print $"Skills: ($skills_str)"
    print "\n======================================"
}
