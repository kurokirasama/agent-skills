# DESIGN.md Format Specification

A `DESIGN.md` file defines a visual identity for coding agents.

## File Structure

1.  **YAML front matter**: Delimited by `---`. Contains machine-readable design tokens.
2.  **Markdown body**: Human-readable design rationale organized into `##` sections.

## Mandatory Section Order

Sections must appear in this order if present:

1.  `## Overview` (or `Brand & Style`)
2.  `## Colors`
3.  `## Typography`
4.  `## Layout` (or `Layout & Spacing`)
5.  `## Elevation & Depth` (or `Elevation`)
6.  `## Shapes`
7.  `## Components`
8.  `## Do's and Don'ts`

## Token Schema (YAML)

Example structure:

```yaml
version: alpha
tokens:
  color:
    primary: "#000000"
    neutral: "#ffffff"
  typography:
    family:
      sans: "Inter, sans-serif"
    size:
      base: "16px"
```

## Validation

Use the official CLI tool:
`npx @google/design.md lint DESIGN.md`