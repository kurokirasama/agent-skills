---
name: cron-update-presupuesto
description: Autonomous daily cron skill to match BANK statement transactions against Budget AutoPay items and mark paid checkboxes in Google Sheets.
cron: "45 0 * * *"
stateful: true
---

# Autonomous Cron Skill: Update Budget AutoPay Transactions (`cron-update-presupuesto`)

## Overview
This skill autonomously queries the current month's BANK statement spreadsheet (e.g. `BANK_2026.10`) inside Google Drive folder `<GOOGLE_SHEET_ID>`, extracts transactions, scans the active `'budget'` tab of spreadsheet `<GOOGLE_SHEET_ID>` for the `AUTOPAY` section, matches transactions using an alias mapping dictionary and amount tolerance comparison, and marks corresponding 'Pagado' checkboxes in Column G as `TRUE`.

Designed for execution via OpenCode / Gemini CLI:
```bash
opn cron cron-update-presupuesto -dbm opencode/deepseek-v4.1-flash-free
```

## Architecture & Workflow

### 1. Drive Statement Discovery
- Scans Google Drive folder `<GOOGLE_SHEET_ID>` for spreadsheets named `BANK_YYYY.MM` matching the current month.
- If the current month file is not yet available, falls back to the most recently modified spreadsheet in the folder.
- If no files exist in the folder, reports cleanly and exits with status `NO_FILE` without modifying any spreadsheets.

### 2. Transaction Ingestion & Normalization
- Reads transactions from `Sheet1!A:E`: `Date`, `Merchant`, `Category`, `Amount`, `Timestamp`.
- Cleans and normalizes Chilean Peso currency amounts (e.g., `"22,990"` -> `22990`, `"1,000,000"` -> `1000000`).

### 3. Budget AutoPay Section Parsing
- Reads spreadsheet `<GOOGLE_SHEET_ID>` tab `'budget'`.
- Detects the `AUTOPAY` section header where Column E is `"AUTOPAY"`.
- Reads down to the next section delimiter (e.g. `"VARIABLE/MANUAL"`).
- Extracts Concepto (Column A), Gasto (Column C), Pagado (Column G), and the exact 1-based sheet row index.

### 4. Smart Matching Engine
- Evaluates transactions against AUTOPAY items using an alias dictionary:
  - `robux`: `["roblox", "robux"]`
  - `genshin`: `["genshin", "cognosphere", "mihoyo"]`
  - `youtube`: `["youtube", "google*youtube"]`
  - `yoosee`: `["yoosee", "yoosee app"]`
  - `uber`: `["uber", "uber *trip", "uber eats"]`
  - `disney+`: `["disney", "disney+", "disney plus"]`
  - `netflix`: `["netflix"]`
  - `bank premium`: `["bank premium", "bank subscription"]`
  - `prime video`: `["prime video", "amazon prime", "amazon video"]`
  - `ai apis`: `["openai", "anthropic", "gemini", "opencode", "ai apis"]`
  - `google ai pro`: `["google *google one", "google ai", "google workspace", "google ai pro"]`
- Cross-validates amounts: allows up to 15% relative difference (to account for USD/CLP exchange rate fluctuations) or up to $2,000 CLP difference.
- Categorizes each AUTOPAY item into:
  - `ALREADY_PAID`: Checkbox is already `TRUE` in Google Sheets (skipped for idempotency).
  - `NEWLY_PAID`: Checkbox is `FALSE`, but a matching transaction was found in the statement.
  - `PENDING`: Checkbox is `FALSE` and no matching transaction was found.

### 5. Checkbox Updating & Idempotency
- Generates batch update payload only for `NEWLY_PAID` items:
  `range: 'budget'!G<rowIndex>`, `values: [[true]]`.
- Dispatches batch update via Google Sheets API `values:batchUpdate`.
- Never un-checks items or alters rows outside the AUTOPAY section.

### 6. Markdown Reporting
- Emits a structured Markdown summary report to `stdout` containing:
  - Statement file name and transaction count.
  - Newly marked items with merchant and amount.
  - Already paid items.
  - Remaining pending items.

## Usage & Execution

### Direct Script Execution
To execute synchronization directly:
```bash
node skills/cron-update-presupuesto/scripts/sync_presupuesto.js
```

### Dry-Run Verification
To evaluate matching and inspect pending updates without modifying Google Sheets:
```bash
node skills/cron-update-presupuesto/scripts/sync_presupuesto.js --dry-run
```

### Crontab Daily Schedule
Configured in crontab for daily execution at 00:45:
```cron
45 0 * * * nu --config /home/username/.config/nushell/config.nu --env-config /home/username/.config/nushell/env.nu -c "opn cron cron-update-presupuesto -dbm opencode/deepseek-v4.1-flash-free"
```

Or for direct Node.js execution:
```cron
45 0 * * * nu --config /home/username/.config/nushell/config.nu --env-config /home/username/.config/nushell/env.nu -c "node /home/username/workspace/llms_configs/skills/cron-update-presupuesto/scripts/sync_presupuesto.js"
```
