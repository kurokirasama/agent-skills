# summarize.nu
# Script to generate a consolidated Markdown summary of research findings

export def generate-summary [papers: list, main_topic: string] {
    mut summary = $"# Research Summary: ($main_topic)\n\n"
    let current_date = date now | format date "%Y-%m-%d %H:%M:%S"
    $summary += $"Date: ($current_date)\n\n"
    
    for paper in $papers {
        $summary += $"## ($paper.title)\n"
        $summary += $"- **Year:** ($paper.year)\n"
        $summary += $"- **Authors:** ($paper.authors)\n"
        let source = ($paper.source? | default 'Unknown')
        $summary += $"- **Source:** ($source)\n"
        $summary += $"- **URL:** ($paper.url)\n"
        $summary += $"- **Abstract:** ($paper.abstract)\n\n"
    }
    
    return $summary
}

export def save-summary [summary: string, research_dir: path] {
    let filename = date now | format date "%Y_%m_%H%M%S.md"
    let output_path = $research_dir | path join $filename
    $summary | save -f $output_path
    return $output_path
}