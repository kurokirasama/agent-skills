const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

// Import helpers (will fail in RED phase until implemented)
const {
  findCurrentMonthMachFile,
  fetchMachTransactions,
  parseMachTransactions,
  parseTransactionAmount
} = require('../scripts/drive_helper.js');

describe('Drive Discovery & BANK Transaction Parser', () => {
  describe('parseTransactionAmount', () => {
    it('parses Chilean Peso strings with commas', () => {
      assert.equal(parseTransactionAmount('22,990'), 22990);
      assert.equal(parseTransactionAmount('1,000,000'), 1000000);
      assert.equal(parseTransactionAmount('2,495'), 2495);
    });

    it('parses strings with dots and leading/trailing whitespace', () => {
      assert.equal(parseTransactionAmount(' 15.500 '), 15500);
      assert.equal(parseTransactionAmount('$8.990'), 8990);
    });

    it('handles numeric input directly', () => {
      assert.equal(parseTransactionAmount(12990), 12990);
      assert.equal(parseTransactionAmount(0), 0);
    });

    it('returns 0 for null, undefined, empty, or non-numeric strings', () => {
      assert.equal(parseTransactionAmount(null), 0);
      assert.equal(parseTransactionAmount(undefined), 0);
      assert.equal(parseTransactionAmount(''), 0);
      assert.equal(parseTransactionAmount('n/a'), 0);
    });
  });

  describe('parseMachTransactions', () => {
    const mockRows = [
      ['Date', 'Merchant', 'Category', 'Amount', 'Timestamp'],
      ['2026-10-10', '  Sisu Spa  ', 'Transferencias', '22,990', '2026-10-11 01:46:11'],
      ['2026-10-12', 'Netflix.com', 'Entretencion', '12,990', '2026-10-13 01:46:11'],
      ['', '', '', '', ''], // empty row
      ['2026-10-15', 'bank subscription', 'Otros', '2,495', '2026-10-16 01:46:11']
    ];

    it('extracts valid transactions and normalizes fields', () => {
      const items = parseMachTransactions(mockRows);
      assert.equal(items.length, 3);

      assert.deepEqual(items[0], {
        date: '2026-10-10',
        merchant: 'Sisu Spa',
        category: 'Transferencias',
        amount: 22990,
        timestamp: '2026-10-11 01:46:11',
        rawAmount: '22,990'
      });

      assert.equal(items[1].merchant, 'Netflix.com');
      assert.equal(items[1].amount, 12990);

      assert.equal(items[2].merchant, 'bank subscription');
      assert.equal(items[2].amount, 2495);
    });

    it('handles null, empty, or rows without headers', () => {
      assert.deepEqual(parseMachTransactions(null), []);
      assert.deepEqual(parseMachTransactions([]), []);
      assert.deepEqual(parseMachTransactions([['Date', 'Merchant', 'Category', 'Amount', 'Timestamp']]), []);
    });
  });

  describe('findCurrentMonthMachFile', () => {
    it('finds exact matching file for current month even if not first in list', async () => {
      const mockFiles = [
        { id: 'file-sep', name: 'BANK_2026.09', modifiedTime: '2026-10-01T00:00:00Z' },
        { id: 'file-oct', name: 'BANK_2026.10', modifiedTime: '2026-10-25T00:00:00Z' }
      ];

      const mockClient = {
        request: async ({ url }) => {
          assert.ok(url.includes('1X_folder_id'));
          return { data: { files: mockFiles } };
        }
      };

      const targetDate = new Date('2026-10-15T12:00:00Z');
      const file = await findCurrentMonthMachFile(mockClient, '1X_folder_id', { targetDate });
      assert.ok(file);
      assert.equal(file.id, 'file-oct');
      assert.equal(file.name, 'BANK_2026.10');
    });

    it('falls back to latest modified file if exact match is missing', async () => {
      const mockFiles = [
        { id: 'file-sep', name: 'BANK_2026.09', modifiedTime: '2026-10-01T00:00:00Z' },
        { id: 'file-aug', name: 'BANK_2026.08', modifiedTime: '2026-09-01T00:00:00Z' }
      ];

      const mockClient = {
        request: async () => ({ data: { files: mockFiles } })
      };

      const targetDate = new Date('2026-11-05T12:00:00Z'); // November (not in mockFiles)
      const file = await findCurrentMonthMachFile(mockClient, '1X_folder_id', { targetDate });
      assert.ok(file);
      assert.equal(file.id, 'file-sep');
    });

    it('returns null if no files exist in folder', async () => {
      const mockClient = {
        request: async () => ({ data: { files: [] } })
      };

      const file = await findCurrentMonthMachFile(mockClient, '1X_folder_id');
      assert.equal(file, null);
    });
  });

  describe('fetchMachTransactions', () => {
    it('fetches sheet rows and returns parsed transactions', async () => {
      const mockClient = {
        request: async ({ url }) => {
          if (url.endsWith('/spreadsheets/test-sheet-id')) {
            return { data: { sheets: [{ properties: { title: 'Sheet1' } }] } };
          }
          if (url.includes('/values/\'Sheet1\'!A:E')) {
            return {
              data: {
                values: [
                  ['Date', 'Merchant', 'Category', 'Amount', 'Timestamp'],
                  ['2026-10-20', 'Roblox', 'Juegos', '11,000', '2026-10-20 15:00:00']
                ]
              }
            };
          }
          throw new Error('Unexpected URL: ' + url);
        }
      };

      const transactions = await fetchMachTransactions(mockClient, 'test-sheet-id');
      assert.equal(transactions.length, 1);
      assert.equal(transactions[0].merchant, 'Roblox');
      assert.equal(transactions[0].amount, 11000);
    });
  });
});
