# skills/gmeet-summary-converter/scripts/parser.nu
# Parser module for Google Meet auto-generated notes and summaries

# Extract Google Docs ID from email text, markdown, or URL string
export def extract-doc-id [input: string] {
  let matched = ($input | parse --regex 'docs\.google\.com/document/d/(?<id>[a-zA-Z0-9_-]+)')
  if ($matched | length) > 0 {
    $matched.0.id
  } else {
    ""
  }
}

# Helper to check if a line is Google Meet disclaimer/footer boilerplate
def is-boilerplate [line: string] {
  let lower = ($line | str downcase)
  let markers = [
    "revisa las notas de gemini"
    "cómo es la calidad de estas notas"
    "obtén sugerencias"
    "el contenido se generó automáticamente"
    "the content was auto-generated"
    "is the content of this email helpful"
    "google llc"
    "archivos adjuntos"
    "registros de la reunión"
  ]
  $markers | any { |m| $lower | str contains $m }
}

# Parse raw Google Meet notes text into structured sections
export def parse-gmeet-text [content: string] {
  let cleaned = ($content | str replace --all "\r" "")
  let lines = ($cleaned | lines | each { |l| $l | str trim })

  # Extract date and title from initial lines
  let header_candidates = ($lines | take while { |l| ($l != "Resumen") and not ($l starts-with "Archivos adjuntos") } | where { |l| ($l | str length) > 0 })
  let date = if ($header_candidates | length) > 0 { $header_candidates.0 } else { "" }
  let title = if ($header_candidates | length) > 1 { $header_candidates.1 } else {
    if ($header_candidates | length) > 0 { $header_candidates.0 } else { "Reunión Google Meet" }
  }

  # Helper to slice lines between section headers
  let resumen_matches = ($lines | enumerate | where item == "Resumen")
  let resumen_idx = if ($resumen_matches | length) > 0 { $resumen_matches.0.index } else { null }

  let pasos_matches = ($lines | enumerate | where item == "Próximos pasos")
  let pasos_idx = if ($pasos_matches | length) > 0 { $pasos_matches.0.index } else { null }

  let detalles_matches = ($lines | enumerate | where item == "Detalles")
  let detalles_idx = if ($detalles_matches | length) > 0 { $detalles_matches.0.index } else { null }

  # Extract summary lines
  let summary_lines = if ($resumen_idx != null) {
    let end_idx = if ($pasos_idx != null) { $pasos_idx } else if ($detalles_idx != null) { $detalles_idx } else { ($lines | length) }
    $lines | skip ($resumen_idx + 1) | take ($end_idx - $resumen_idx - 1) | where { |l| (($l | str length) > 0) and not (is-boilerplate $l) }
  } else {
    []
  }

  # Extract action items / next steps
  let tasks = if ($pasos_idx != null) {
    let end_idx = if ($detalles_idx != null) { $detalles_idx } else { ($lines | length) }
    let raw_tasks = ($lines | skip ($pasos_idx + 1) | take ($end_idx - $pasos_idx - 1) | where { |l| (($l | str length) > 0) and not (is-boilerplate $l) })
    $raw_tasks | each { |task_line|
      let parsed_task = ($task_line | parse --regex '^\[(?<assignee>[^\]]+)\]\s*(?<action>[^:]+):\s*(?<details>.*)$')
      if ($parsed_task | length) > 0 {
        {
          assignee: ($parsed_task.0.assignee | str trim)
          action: ($parsed_task.0.action | str trim)
          details: ($parsed_task.0.details | str trim)
        }
      } else {
        {
          assignee: "General"
          action: "Acción"
          details: $task_line
        }
      }
    }
  } else {
    []
  }

  # Extract discussion details
  let details = if ($detalles_idx != null) {
    let raw_details = ($lines | skip ($detalles_idx + 1) | where { |l| (($l | str length) > 0) and not (is-boilerplate $l) })
    $raw_details | each { |det_line|
      let parts = ($det_line | split row --number 2 ":")
      if ($parts | length) == 2 {
        {
          topic: ($parts.0 | str trim)
          content: ($parts.1 | str trim)
        }
      } else {
        {
          topic: "Punto Tratado"
          content: $det_line
        }
      }
    }
  } else {
    []
  }

  {
    title: $title
    date: $date
    summary: $summary_lines
    tasks: $tasks
    details: $details
  }
}

# Parse Google Docs API structure or raw notes
export def parse-gmeet-notes [doc_data: any] {
  let structured = if ($doc_data | describe | str starts-with "string") {
    let trimmed = ($doc_data | str trim)
    if ($trimmed starts-with "{") and ($trimmed ends-with "}") {
      try { $trimmed | from json } catch { $doc_data }
    } else {
      $doc_data
    }
  } else {
    $doc_data
  }

  let content = if ($structured | describe | str starts-with "record") {
    if ("tabs" in $structured) and (($structured.tabs | length) > 0) {
      $structured.tabs.0.content
    } else if ("content" in $structured) {
      $structured.content
    } else {
      $structured | to json
    }
  } else {
    $structured | into string
  }

  parse-gmeet-text $content
}
