# skills/academic-evaluator/mod.nu
# Helper commands for multi-modal academic evaluations

# Formats a single rubric item into a compact plain text bullet line
export def format-speedgrader-item [
    item: record<criterion: string, score: any, max: any, level: string, comment: string>
] {
    $"• Criterio ($item.criterion): ($item.score)/($item.max) \(($item.level)\) | ($item.comment)"
}

# Formats an entire rubric evaluation into plain text suitable for Canvas SpeedGrader comments
export def format-speedgrader-rubric [
    items: list<any>
    --feedback: string = ""
] {
    let lines = ($items | each { |i| format-speedgrader-item $i })
    let formatted_items = ($lines | str join (char nl))
    if ($feedback | str length) > 0 {
        $formatted_items + (char nl) + (char nl) + "Comentarios Generales:" + (char nl) + $feedback
    } else {
        $formatted_items
    }
}

# Calculates final Chilean scale (1.0 to 7.0) grade from raw points and max points
export def calculate-final-grade [
    points: any
    --max: any = 60.0
    --decimals: int = 1
] {
    let pts = ($points | into float)
    let mx = ($max | into float)
    let raw_grade = if $mx == 60.0 {
        ($pts + 10.0) / 10.0
    } else {
        (($pts / $mx) * 6.0) + 1.0
    }
    let bounded = if $raw_grade > 7.0 { 7.0 } else if $raw_grade < 1.0 { 1.0 } else { $raw_grade }
    $bounded | math round --precision $decimals
}

# Standardizes submission metadata into an auditable manifest
export def build-submission-manifest [
    entries: list<any>
] {
    $entries | each { |e|
        $e | insert registered_at (date now | format date "%Y-%m-%dT%H:%M:%S%z")
    }
}

# Reconciles professor evaluations against teaching assistant / co-grader evaluations
export def reconcile-ta-evaluations [
    prof_evals: list<any>
    ta_evals: list<any>
    --threshold: float = 0.5
] {
    $prof_evals | each { |p|
        let match = ($ta_evals | where student == $p.student)
        let ta_grade = if ($match | is-empty) { null } else { $match | get 0.grade | into float }
        let p_grade = ($p.grade | into float)
        let delta = if $ta_grade == null { null } else { ($p_grade - $ta_grade) | math abs | math round --precision 2 }
        let discrepancy = if $delta == null { true } else { $delta > $threshold }
        {
            student: $p.student
            prof_grade: $p_grade
            ta_grade: $ta_grade
            delta: $delta
            discrepancy: $discrepancy
            reconciliation_needed: $discrepancy
        }
    }
}

# Segments transcript text by ordered delimiter markers
export def segment-transcript-boundaries [
    transcript: string
    markers: list<string>
] {
    let total_markers = ($markers | length)
    0..($total_markers - 1) | each { |idx|
        let curr_marker = ($markers | get $idx)
        let parts = ($transcript | split row $curr_marker)
        if ($parts | length) > 1 {
            let after = ($parts | skip 1 | str join $curr_marker)
            let segment_content = if $idx < ($total_markers - 1) {
                let next_marker = ($markers | get ($idx + 1))
                ($after | split row $next_marker | first)
            } else {
                $after
            }
            {
                marker: $curr_marker
                content: ($segment_content | str trim)
            }
        } else {
            {
                marker: $curr_marker
                content: ""
            }
        }
    }
}
