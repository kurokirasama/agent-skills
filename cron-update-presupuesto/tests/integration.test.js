const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

// Import orchestrator (will fail in RED phase until implemented)
const { syncBudgetAutoPay, formatMarkdownReport } = require('../scripts/sync_presupuesto.js');

describe('End-to-End Budget AutoPay Sync Pipeline', () => {
  const mockFolderFiles = [
    { id: 'bank-file-10', name: 'BANK_2026.10', modifiedTime: '2026-10-25T00:00:00Z' }
  ];

  const mockMachRows = [
    ['Date', 'Merchant', 'Category', 'Amount', 'Timestamp'],
    ['2026-10-12', 'Netflix.com', 'Entretencion', '12,990', '2026-10-12 12:00:00'],
    ['2026-10-14', 'Google*YouTube', 'Suscripciones', '11,000', '2026-10-14 12:00:00'],
    ['2026-10-15', 'Roblox Corp', 'Juegos', '11,000', '2026-10-15 12:00:00']
  ];

  const mockBudgetRows = [
    ['Concepto', 'Ingreso', 'Gasto', 'Saldo', 'Columna 1', 'Nota', 'Pagado'],
    ['', '', '', '', 'AUTOPAY', '', '0'], // Row 2
    ['robux', '', '11000', '', '', '', 'TRUE'], // Row 3 (already paid)
    ['netflix', '', '12990', '', '', '', 'FALSE'], // Row 4 (newly paid)
    ['youtube', '', '11000', '', '', '', 'FALSE'], // Row 5 (newly paid)
    ['disney+', '', '8990', '', '', '', 'FALSE'], // Row 6 (pending)
    ['', '', '', '', 'VARIABLE/MANUAL', '', '0']
  ];

  function createMockClient() {
    const apiCalls = [];
    return {
      apiCalls,
      request: async (opts) => {
        apiCalls.push(opts);
        const url = opts.url || '';

        // Drive discovery
        if (url.includes('/drive/v3/files')) {
          return { data: { files: mockFolderFiles } };
        }
        // BANK metadata
        if (url.includes('/spreadsheets/bank-file-10') && !url.includes('/values/')) {
          return { data: { sheets: [{ properties: { title: 'Sheet1' } }] } };
        }
        // BANK values
        if (url.includes('/spreadsheets/bank-file-10/values/')) {
          return { data: { values: mockMachRows } };
        }
        // Budget values
        if (url.includes('/spreadsheets/budget-sheet-id/values/')) {
          return { data: { values: mockBudgetRows } };
        }
        // Batch update
        if (url.includes('/values:batchUpdate')) {
          return { data: { totalUpdatedRows: opts.data?.data?.length || 0 } };
        }

        throw new Error('Unhandled URL in mock client: ' + url);
      }
    };
  }

  it('executes full pipeline, updates checkboxes for newly paid items, and outputs report', async () => {
    const mockClient = createMockClient();
    const logs = [];

    const summary = await syncBudgetAutoPay({
      client: mockClient,
      folderId: 'folder-123',
      spreadsheetId: 'budget-sheet-id',
      tabName: 'budget',
      dryRun: false,
      logger: (msg) => logs.push(msg)
    });

    assert.equal(summary.status, 'SUCCESS');
    assert.equal(summary.fileName, 'BANK_2026.10');
    assert.equal(summary.newlyPaidCount, 2); // netflix, youtube
    assert.equal(summary.alreadyPaidCount, 1); // robux
    assert.equal(summary.pendingCount, 1); // disney+

    // Verify batchUpdate was called
    const batchUpdateCall = mockClient.apiCalls.find(c => c.url.includes('/values:batchUpdate'));
    assert.ok(batchUpdateCall, 'Expected values:batchUpdate to be called');
    assert.equal(batchUpdateCall.data.data.length, 2);
    assert.deepEqual(batchUpdateCall.data.data.map(d => d.range), [
      "'budget'!G4",
      "'budget'!G5"
    ]);

    // Verify report format
    assert.ok(summary.report.includes('### Newly Marked as Paid'));
    assert.ok(summary.report.includes('netflix'));
    assert.ok(summary.report.includes('youtube'));
    assert.ok(summary.report.includes('robux'));
    assert.ok(summary.report.includes('disney+'));
  });

  it('skips Sheets updates when dryRun is true', async () => {
    const mockClient = createMockClient();

    const summary = await syncBudgetAutoPay({
      client: mockClient,
      folderId: 'folder-123',
      spreadsheetId: 'budget-sheet-id',
      tabName: 'budget',
      dryRun: true,
      logger: () => {}
    });

    assert.equal(summary.status, 'SUCCESS');
    assert.equal(summary.dryRun, true);
    assert.equal(summary.newlyPaidCount, 2);

    // Verify batchUpdate was NOT called
    const batchUpdateCall = mockClient.apiCalls.find(c => c.url.includes('/values:batchUpdate'));
    assert.equal(batchUpdateCall, undefined);
  });

  it('handles missing statement file cleanly without error', async () => {
    const mockClient = {
      request: async () => ({ data: { files: [] } })
    };

    const summary = await syncBudgetAutoPay({
      client: mockClient,
      folderId: 'empty-folder',
      spreadsheetId: 'budget-sheet-id',
      logger: () => {}
    });

    assert.equal(summary.status, 'NO_FILE');
    assert.equal(summary.newlyPaidCount, 0);
  });
});
