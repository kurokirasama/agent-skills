# skills/gmeet-summary-converter/scripts/synthesizer.nu
# Synthesizer module for generating meeting minutes and signature tables per meeting-summarizer standards

# Extract and deduplicate participants and their titles/institutions from parsed meeting data
export def extract-participants [parsed: record] {
  mut people = []
  let non_person_blacklist = [
    "Bío Bío"
    "Bio Bío"
    "Bio Bio"
    "Instituto Nacional"
    "Universidad del"
    "Universidad de"
    "Consejo Asesor"
    "Próximos Pasos"
    "Google LLC"
    "Detalles"
    "Resumen"
  ]

  # 1. Scan discussion details for explicit person introductions: "Name, Title/Role"
  for det in ($parsed.details | default []) {
    let text = $"($det.topic) ($det.content)"
    # Match patterns like: "Nombre Apellido, cargo..." or "Nombre Apellido (XX), cargo..."
    let matches = ($text | parse --regex '(?<name>[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)+)(?:\s*\((?<initials>[A-Z]+)\))?,\s*(?<role>[^,.\n]+(?:(?:de|del|la|el|en)\s+[^,.\n]+)*)')
    for m in $matches {
      let clean_name = ($m.name | str trim)
      let clean_role = ($m.role | str trim)
      let is_blacklisted = ($non_person_blacklist | any { |b| $clean_name | str contains $b })
      if ($clean_name | str length) > 3 and not $is_blacklisted {
        $people = ($people | append { name: $clean_name, role: $clean_role })
      }
    }

    # Also handle initial aliases like "LG, director de escuela..."
    let alias_matches = ($text | parse --regex '\b(?<alias>[A-Z]{2,3}),\s*(?<role>[^,.\n]+(?:(?:de|del|la|el|en)\s+[^,.\n]+)*)')
    for am in $alias_matches {
      let alias = ($am.alias | str trim)
      let role = ($am.role | str trim)
      # Check if any task assignee matches these initials (e.g., Author Name -> LG)
      for t in ($parsed.tasks | default []) {
        let task_name = ($t.assignee | str trim)
        let initials = ($task_name | split words | each { |w| $w | str substring 0..0 } | str join "")
        if $initials == $alias {
          $people = ($people | append { name: $task_name, role: $role })
        }
      }
    }
  }

  # 2. Collect assignees from tasks who weren't captured with roles
  for t in ($parsed.tasks | default []) {
    let name = ($t.assignee | str trim)
    if ($name | str length) > 2 and ($name != "General") {
      let already_found = ($people | any { |p| $p.name == $name })
      if not $already_found {
        $people = ($people | append { name: $name, role: "Participante" })
      }
    }
  }

  # Deduplicate by name, preferring entries with descriptive roles over generic "Participante"
  let deduped = ($people | reduce -f [] { |it, acc|
    let existing_idx = ($acc | enumerate | where { |x| $x.item.name == $it.name } | get -o 0.index)
    if ($existing_idx == null) {
      $acc | append $it
    } else {
      let existing = ($acc | get $existing_idx)
      if ($existing.role == "Participante") and ($it.role != "Participante") {
        $acc | update $existing_idx $it
      } else {
        $acc
      }
    }
  })

  $deduped
}

# Generate Pandoc/LaTeX-compatible Markdown signature table
export def generate-signature-table [participants: list] {
  let header = [
    "| N° | Nombre y Apellidos | Cargo / Institución | Firma |"
    "| :---: | :--- | :--- | :---: |"
  ]

  let rows = ($participants | enumerate | each { |p|
    let num = ($p.index + 1)
    let name = $p.item.name
    let role = ($p.item.role | default "Participante")
    $"| ($num) | ($name) | ($role) | `__________________________` |"
  })

  ($header | append $rows | str join "\n")
}

# Synthesize full meeting minutes following meeting-summarizer specifications
export def synthesize-minutes [parsed: record] {
  let title = $parsed.title
  let date = $parsed.date

  # Section 1: Resumen
  let summary_items = ($parsed.summary | each { |s| $"- ($s)" } | str join "\n")
  let resumen_section = $"# Resumen\n\n**Fecha:** ($date)\n**Título:** ($title)\n\n($summary_items)"

  # Section 2: Contenido
  let contenido_items = ($parsed.details | each { |d|
    $"### ($d.topic)\n\n($d.content)"
  } | str join "\n\n")
  let contenido_section = $"# Contenido\n\n($contenido_items)"

  # Section 3: Tareas
  let tareas_items = ($parsed.tasks | each { |t|
    $"- [ ] **[($t.assignee)]**: ($t.action): ($t.details)"
  } | str join "\n")
  let tareas_section = $"# Tareas\n\n($tareas_items)"

  # Section 4: Participantes y Firmas
  let participants = (extract-participants $parsed)
  let sig_table = (generate-signature-table $participants)
  let firmas_section = $"# Participantes y Firmas\n\n($sig_table)"

  # Combine all sections
  [
    $resumen_section
    $contenido_section
    $tareas_section
    $firmas_section
  ] | str join "\n\n"
}
