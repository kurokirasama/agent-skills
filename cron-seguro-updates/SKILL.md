---
name: cron-seguro-updates
description: Autonomous daily cron skill to ingest INSURANCE insurance emails (denuncios and liquidaciones), parse claim statuses, and sync them to Google Sheet Insurance Tracker.
cron: "15 0 * * *"
stateful: true
---

# Autonomous Cron Skill: Seguro Updates (`cron-seguro-updates`)

## Overview
This skill autonomously ingests and parses claim emails from INSURANCE (`support@insurance.example.com` and `support@insurance.example.com`), synchronizes new medical insurance claims (`Claim Notice`) and processed settlements (`Settlement Notice INSURANCE`) to Google Sheet **Insurance Tracker** (`<GOOGLE_SHEET_ID>`), and manages message lifecycle using Gmail label `seguro/procesado`.

Designed for execution via OpenCode / Gemini CLI:
```bash
opn cron cron-seguro-updates -dbm opencode/deepseek-v4.1-flash-free
```

## Architecture & Workflow

### 1. Label Management
- Inspects Gmail labels to ensure `seguro/procesado` exists.
- If missing, automatically creates the label via Google Workspace API with visibility enabled (`labelShow` / `show`).

### 2. Message Search & Thread Decomposition
- Queries all INSURANCE messages (inbox + archived, paginated) not labeled `seguro/procesado`; SPAM/TRASH are excluded by the Gmail API default:
  ```text
  (from:support@insurance.example.com OR from:support@insurance.example.com OR subject:"Claim Notice" OR subject:"Settlement Notice") -label:seguro/procesado
  ```
- Evaluates individual messages within threads to ensure granular claim tracking and avoid re-processing older notifications.

### 3. Claim Denuncio Ingestion (`Claim Notice <id>`)
- Parses `Nº Solicitud` (e.g. `341034`).
- Note: denuncio emails carry **no attachments** (verified); only the email body is available at this stage.
- Verifies whether the claim already exists in `Insurance Tracker` to prevent duplicate row entries.
- If not present:
  - Prepends a new row at Row 2 (directly below the header row):
    - **Column A (`Nº Solicitud`)**: formatted claim number (`341,034.00`).
    - **Column B (`Beneficiario`)**: extracted from the email body greeting (`Estimado(a) <name> ...`).
    - **Column C (`Valor Reclamado`)**: empty until the liquidation PDF arrives.
    - **Column D (`Devolución`)**: empty.
    - **Column E (`Estado`)**: `"Denunciado"`.
    - **Column F (`Item`)**: predicted medical prestation from email text/snippets and historical vocabulary (`peg`, `eval plantillas`, `specialist_a`, `plantillas`, `med specialist`, `treatment_a`, `therapy_a`, `compounded`, `test cutaneo`, `alergia`, `medicamentos`, `derma`); enriched later from the liquidation PDF.
    - **Column G (`Fecha Liquidacion`)**: empty.
- Applies label `seguro/procesado` and removes `UNREAD`.

### 4. Liquidation Settlement Processing (`Settlement Notice INSURANCE ... <id>.pdf`)
- Extracts `Nº Solicitud` (e.g. `339814`) from attachment filename (`1000 - 12345678 - <solicitud>.pdf`) or subject line.
- Extracts `Fecha Liquidacion` from body (`procesada con fecha DD-MM-YYYY`).
- **PDF enrichment (fill-only-blanks):** downloads the attached PDF, extracts its text with `pdftotext -layout`, and parses:
  - **Beneficiario** ← `Identificación Paciente` (patient name).
  - **Valor Reclamado** ← `SubTotal` `Valor Prest.` amount.
  - **Item** ← `Prestación` text (vocabulary match first; otherwise the normalized prestación text).
  - **Reconciliation (PDF is authoritative):** Beneficiario (B) and Valor Reclamado (C) are compared against the sheet — names order/accent-insensitively, amounts numerically — and corrected when they differ, logging each change as `[RECONCILE] <col>: "<old>" -> "<new>"`. Item (F) is filled only when empty. Empty PDF values never overwrite existing data.
  - If the attachment or `pdftotext` fails, a warning is logged and the body-based processing continues.
- Determines settlement outcome:
  - **Approved**: Body states payment (`Procederemos a realizar el pago correspondiente a $ <monto>...`).
    - Updates **Column E (`Estado`)**: `"Liquidado"`.
    - Updates **Column D (`Devolución`)**: parsed integer amount.
    - Updates **Column G (`Fecha Liquidacion`)**: processed date.
  - **Rejected**: Body states no reimbursement / rejection.
    - Updates **Column E (`Estado`)**: `"Rechazado"`.
    - Updates **Column G (`Fecha Liquidacion`)**: processed date.
- Applies label `seguro/procesado` and removes `UNREAD`.

## Usage & Execution

### Direct Script Execution
To execute synchronization directly:
```bash
node skills/cron-seguro-updates/scripts/sync_seguro.js
```

### Dry-Run Verification
To inspect and evaluate unprocessed messages without modifying Google Sheets or applying Gmail labels:
```bash
node skills/cron-seguro-updates/scripts/sync_seguro.js --dry-run
```

### Historical Reconciliation (`--reconcile-all`)
Reprocesses **all INSURANCE mail** (labeled or not) to reconcile historical spreadsheet rows against their liquidation PDFs, including previously unlabeled or legacy emails:
```bash
node skills/cron-seguro-updates/scripts/sync_seguro.js --reconcile-all
```
Each corrected field is logged as `[RECONCILE]`; a second run reports no changes (idempotent).

### Crontab Daily Schedule
Configured in crontab for daily execution at 00:15:
```cron
15 0 * * * nu --config /home/username/.config/nushell/config.nu --env-config /home/username/.config/nushell/env.nu -c "opn cron cron-seguro-updates -dbm opencode/deepseek-v4.1-flash-free"
```

Or for direct Node.js execution:
```cron
15 0 * * * nu --config /home/username/.config/nushell/config.nu --env-config /home/username/.config/nushell/env.nu -c "node /home/username/workspace/llms_configs/skills/cron-seguro-updates/scripts/sync_seguro.js"
```

