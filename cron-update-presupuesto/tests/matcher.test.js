const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

// Import matcher helpers (will fail in RED phase until implemented)
const {
  ALIAS_MAP,
  matchSinglePacItem,
  matchPacTransactions,
  generateCheckboxUpdates,
  markPacRowPaid,
  updatePacCheckboxes
} = require('../scripts/matcher.js');

describe('Smart Matching & Checkbox Update Engine', () => {
  const mockPacItems = [
    { rowIndex: 16, concepto: 'robux', gasto: 11000, pagado: true, nota: '' },
    { rowIndex: 17, concepto: 'genshin', gasto: 3900, pagado: false, nota: '' },
    { rowIndex: 18, concepto: 'youtube', gasto: 11000, pagado: false, nota: '' },
    { rowIndex: 21, concepto: 'disney+', gasto: 8990, pagado: false, nota: '' },
    { rowIndex: 22, concepto: 'netflix', gasto: 12990, pagado: false, nota: '' },
    { rowIndex: 23, concepto: 'BANK Premium ', gasto: 2495, pagado: false, nota: '' }
  ];

  const mockTransactions = [
    { date: '2026-10-10', merchant: 'ROBLOX Corp', amount: 11000, rawAmount: '11,000' },
    { date: '2026-10-12', merchant: 'Netflix.com', amount: 12990, rawAmount: '12,990' },
    { date: '2026-10-15', merchant: 'bank subscription', amount: 2495, rawAmount: '2,495' },
    { date: '2026-10-18', merchant: 'Google*YouTube', amount: 11450, rawAmount: '11,450' }, // slight variance
    { date: '2026-10-20', merchant: 'JUMBO Hualpen', amount: 85000, rawAmount: '85,000' } // unrelated
  ];

  describe('matchSinglePacItem', () => {
    it('matches netflix with exact amount', () => {
      const pacItem = { concepto: 'netflix', gasto: 12990, pagado: false };
      const matched = matchSinglePacItem(pacItem, mockTransactions);
      assert.ok(matched);
      assert.equal(matched.merchant, 'Netflix.com');
      assert.equal(matched.amount, 12990);
    });

    it('matches youtube with minor currency exchange variance (<15%)', () => {
      const pacItem = { concepto: 'youtube', gasto: 11000, pagado: false };
      const matched = matchSinglePacItem(pacItem, mockTransactions);
      assert.ok(matched);
      assert.equal(matched.merchant, 'Google*YouTube');
    });

    it('matches BANK Premium with alias bank subscription', () => {
      const pacItem = { concepto: 'BANK Premium ', gasto: 2495, pagado: false };
      const matched = matchSinglePacItem(pacItem, mockTransactions);
      assert.ok(matched);
      assert.equal(matched.merchant, 'bank subscription');
    });

    it('rejects match if amount difference exceeds tolerance (>15% and >2000)', () => {
      const pacItem = { concepto: 'netflix', gasto: 12990, pagado: false };
      const badTransactions = [
        { merchant: 'Netflix.com', amount: 35000 } // way too high
      ];
      const matched = matchSinglePacItem(pacItem, badTransactions);
      assert.equal(matched, null);
    });

    it('returns null when no matching merchant is found', () => {
      const pacItem = { concepto: 'disney+', gasto: 8990, pagado: false };
      const matched = matchSinglePacItem(pacItem, mockTransactions);
      assert.equal(matched, null);
    });
  });

  describe('matchPacTransactions', () => {
    it('categorizes items into ALREADY_PAID, NEWLY_PAID, and PENDING', () => {
      const results = matchPacTransactions(mockPacItems, mockTransactions);
      assert.equal(results.length, 6);

      const robux = results.find(r => r.pacItem.concepto === 'robux');
      assert.equal(robux.status, 'ALREADY_PAID');
      assert.ok(robux.matchedTransaction);

      const netflix = results.find(r => r.pacItem.concepto === 'netflix');
      assert.equal(netflix.status, 'NEWLY_PAID');
      assert.equal(netflix.matchedTransaction.merchant, 'Netflix.com');

      const youtube = results.find(r => r.pacItem.concepto === 'youtube');
      assert.equal(youtube.status, 'NEWLY_PAID');

      const machPremium = results.find(r => r.pacItem.concepto === 'BANK Premium ');
      assert.equal(machPremium.status, 'NEWLY_PAID');

      const disney = results.find(r => r.pacItem.concepto === 'disney+');
      assert.equal(disney.status, 'PENDING');
      assert.equal(disney.matchedTransaction, null);

      const genshin = results.find(r => r.pacItem.concepto === 'genshin');
      assert.equal(genshin.status, 'PENDING');
    });
  });

  describe('generateCheckboxUpdates', () => {
    it('generates Sheets batch update payload only for NEWLY_PAID items', () => {
      const matches = matchPacTransactions(mockPacItems, mockTransactions);
      const updates = generateCheckboxUpdates(matches, 'budget');

      assert.equal(updates.length, 3); // netflix (row 22), youtube (row 18), bank premium (row 23)
      assert.deepEqual(updates.map(u => u.range), [
        "'budget'!G18",
        "'budget'!G22",
        "'budget'!G23"
      ]);
      assert.deepEqual(updates[0].values, [[true]]);
    });

    it('returns empty array if no newly paid items exist', () => {
      const allPaid = [{ pacItem: { rowIndex: 5, pagado: true }, status: 'ALREADY_PAID' }];
      assert.deepEqual(generateCheckboxUpdates(allPaid), []);
    });
  });

  describe('updatePacCheckboxes & markPacRowPaid', () => {
    it('sends batchUpdate request to Google Sheets when updates exist', async () => {
      let requestPayload = null;
      const mockClient = {
        request: async (opts) => {
          requestPayload = opts;
          return { data: { totalUpdatedRows: 2 } };
        }
      };

      const updates = [
        { range: "'budget'!G18", values: [[true]] },
        { range: "'budget'!G22", values: [[true]] }
      ];

      const res = await updatePacCheckboxes(mockClient, 'spreadsheet-id', updates);
      assert.equal(res.updatedCount, 2);
      assert.ok(requestPayload.url.includes('/values:batchUpdate'));
      assert.equal(requestPayload.method, 'POST');
      assert.deepEqual(requestPayload.data.data, updates);
    });

    it('returns 0 count without calling API when updates is empty', async () => {
      let called = false;
      const mockClient = {
        request: async () => { called = true; }
      };

      const res = await updatePacCheckboxes(mockClient, 'spreadsheet-id', []);
      assert.equal(res.updatedCount, 0);
      assert.equal(called, false);
    });

    it('markPacRowPaid sends individual update request for single row', async () => {
      let requestPayload = null;
      const mockClient = {
        request: async (opts) => {
          requestPayload = opts;
          return { data: { updatedRows: 1 } };
        }
      };

      await markPacRowPaid(mockClient, 'spreadsheet-id', 22, 'budget');
      assert.ok(requestPayload.url.includes("/values/'budget'!G22"));
      assert.equal(requestPayload.method, 'PUT');
      assert.deepEqual(requestPayload.data.values, [[true]]);
    });
  });
});
