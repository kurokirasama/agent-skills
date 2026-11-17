#!/usr/bin/env node
/**
 * sync_presupuesto.js
 * Orchestrator script for autonomous AUTOPAY transaction matching and updating in Google Sheets.
 */

const {
  getGoogleClient,
  findCurrentMonthMachFile,
  fetchMachTransactions
} = require('./drive_helper.js');

const {
  DEFAULT_BUDGET_SPREADSHEET_ID,
  DEFAULT_BUDGET_TAB,
  fetchPacSection
} = require('./autopay_parser.js');

const {
  matchPacTransactions,
  generateCheckboxUpdates,
  updatePacCheckboxes
} = require('./matcher.js');

const DEFAULT_DRIVE_FOLDER_ID = '<GOOGLE_SHEET_ID>';

/**
 * Formats the synchronization result into a clean Markdown report.
 */
function formatMarkdownReport({
  fileName,
  fileId,
  totalTransactions,
  newlyPaid,
  alreadyPaid,
  pending,
  dryRun
}) {
  const lines = [
    '# Budget AutoPay Transactions Report',
    '',
    `- **BANK Statement**: \`${fileName || 'N/A'}\` (${totalTransactions} transactions parsed)`,
    `- **Dry Run Mode**: ${dryRun ? 'Yes (No Sheets modifications applied)' : 'No (Live updates applied)'}`,
    '',
    '## Summary',
    `- **Newly Marked as Paid**: ${newlyPaid.length}`,
    `- **Already Marked as Paid**: ${alreadyPaid.length}`,
    `- **Pending / Unpaid**: ${pending.length}`,
    ''
  ];

  if (newlyPaid.length > 0) {
    lines.push('### Newly Marked as Paid');
    for (const m of newlyPaid) {
      const tx = m.matchedTransaction;
      lines.push(`- [x] **${m.pacItem.concepto}** ($${m.pacItem.gasto.toLocaleString('es-CL')}) -> \`${tx.merchant}\` ($${tx.amount.toLocaleString('es-CL')}) [Row ${m.pacItem.rowIndex}]`);
    }
    lines.push('');
  }

  if (alreadyPaid.length > 0) {
    lines.push('### Already Paid');
    for (const m of alreadyPaid) {
      const txInfo = m.matchedTransaction ? ` -> matched \`${m.matchedTransaction.merchant}\`` : '';
      lines.push(`- [x] **${m.pacItem.concepto}** ($${m.pacItem.gasto.toLocaleString('es-CL')})${txInfo} [Row ${m.pacItem.rowIndex}]`);
    }
    lines.push('');
  }

  if (pending.length > 0) {
    lines.push('### Pending AUTOPAY Items');
    for (const m of pending) {
      lines.push(`- [ ] **${m.pacItem.concepto}** ($${m.pacItem.gasto.toLocaleString('es-CL')}) [Row ${m.pacItem.rowIndex}]`);
    }
    lines.push('');
  }

  return lines.join('\n');
}

/**
 * Main AUTOPAY synchronization engine.
 */
async function syncBudgetAutoPay({
  client = null,
  folderId = DEFAULT_DRIVE_FOLDER_ID,
  spreadsheetId = DEFAULT_BUDGET_SPREADSHEET_ID,
  tabName = DEFAULT_BUDGET_TAB,
  dryRun = false,
  targetDate = new Date(),
  logger = console.log
} = {}) {
  if (!client) {
    client = await getGoogleClient();
  }

  // 1. Locate current month statement in Drive
  const file = await findCurrentMonthMachFile(client, folderId, { targetDate });
  if (!file) {
    const msg = '# Budget AutoPay Transactions Report\n\nNo BANK statement file found in Google Drive folder.';
    logger(msg);
    return {
      status: 'NO_FILE',
      newlyPaidCount: 0,
      alreadyPaidCount: 0,
      pendingCount: 0,
      dryRun,
      report: msg
    };
  }

  // 2. Ingest transactions from BANK statement
  const transactions = await fetchMachTransactions(client, file.id);

  // 3. Scan AUTOPAY section from target budget spreadsheet
  const autopay = await fetchPacSection(client, spreadsheetId, tabName);

  // 4. Perform smart matching
  const matches = matchPacTransactions(autopay.pacItems, transactions);

  const newlyPaid = matches.filter(m => m.status === 'NEWLY_PAID');
  const alreadyPaid = matches.filter(m => m.status === 'ALREADY_PAID');
  const pending = matches.filter(m => m.status === 'PENDING');

  // 5. Generate and dispatch Sheets updates
  const updates = generateCheckboxUpdates(matches, tabName);
  let updateResult = null;
  if (!dryRun && updates.length > 0) {
    updateResult = await updatePacCheckboxes(client, spreadsheetId, updates);
  }

  // 6. Generate Markdown report
  const report = formatMarkdownReport({
    fileName: file.name,
    fileId: file.id,
    totalTransactions: transactions.length,
    newlyPaid,
    alreadyPaid,
    pending,
    dryRun
  });

  logger(report);

  return {
    status: 'SUCCESS',
    fileName: file.name,
    fileId: file.id,
    totalTransactions: transactions.length,
    newlyPaidCount: newlyPaid.length,
    alreadyPaidCount: alreadyPaid.length,
    pendingCount: pending.length,
    updates,
    updateResult,
    dryRun,
    report
  };
}

// CLI entry point
if (require.main === module) {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run') || args.includes('-d');

  syncBudgetAutoPay({ dryRun })
    .then((summary) => {
      process.exit(summary.status === 'SUCCESS' ? 0 : 1);
    })
    .catch((err) => {
      console.error('[AUTOPAY Sync Error]', err);
      process.exit(1);
    });
}

module.exports = {
  DEFAULT_DRIVE_FOLDER_ID,
  formatMarkdownReport,
  syncBudgetAutoPay
};
