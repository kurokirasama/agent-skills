# research.nu
# Script to coordinate the autonomous research loop

source persistence.nu
source process_paper.nu
source summarize.nu

export def run-research [research_dir: path] {
    let last_updated = get-last-updated $research_dir
    let current_run_date = date now
    
    print $"Starting research for papers since ($last_updated | format date '%Y-%m-%d')..."
    
    # In a real run, this would be performed by the agent using tools.
}

export def finalize-research [research_dir: path, papers: list, main_topic: string] {
    if ($papers | is-empty) {
        print "No new papers found."
        set-last-updated $research_dir (date now)
        return
    }
    
    print $"Generating summary for ($papers | length) papers..."
    let summary = generate-summary $papers $main_topic
    
    print "Saving summary..."
    let summary_path = save-summary $summary $research_dir
    
    print "\n--- RESEARCH SUMMARY ---\n"
    print $summary
    print "\n------------------------\n"
    
    # Update DOIs
    for paper in $papers {
        if ($paper.doi? != null) {
            add-processed-doi $research_dir $paper.doi
        }
    }
    
    print "Updating last_updated date..."
    set-last-updated $research_dir (date now)
}

export def filter-by-date [results: list, last_updated: datetime] {
    return ($results | where { ($in.published | into datetime) > $last_updated })
}

export def is-paper-new [research_dir: path, title: string, doi: string = ""] {
    # 1. Check by DOI first (more robust)
    if $doi != "" {
        if (is-doi-processed $research_dir $doi) {
            return false
        }
    }
    
    # 2. Check if a paper with this title (or similar) already exists in the directory
    let sanitized_title = $title | str replace --all ' ' '_' | str replace --all '[^a-zA-Z0-9_]' '' | str lowercase
    let exists = ls $research_dir | where name =~ $sanitized_title | is-not-empty
    return (not $exists)
}