const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

// Import helper (will fail in RED phase until implemented)
const {
  parsePacSection,
  fetchPacSection,
  DEFAULT_BUDGET_SPREADSHEET_ID
} = require('../scripts/autopay_parser.js');

describe('AUTOPAY Section Parser for budget tab', () => {
  const mockBudgetRows = [
    ['Concepto', 'Ingreso', 'Gasto', 'Saldo', 'Columna 1', 'Nota', 'Pagado'],
    ['work', '2469712', '', '', '', '', '0'],
    ['', '', '', '', 'FIJO/MANUAL', '', '0'],
    ['hipotecario', '', '514857', '', '', '63/300', 'TRUE'],
    ['mama', '', '200000', '', '', '', 'FALSE'],
    ['', '', '', '', 'AUTOPAY', '', '0'], // Row 6 (1-based)
    ['robux', '', '11000', '', '', '', 'TRUE'], // Row 7
    ['genshin', '', '3900', '', '', '', 'FALSE'], // Row 8
    ['youtube', '', '11000', '', '', '', 'FALSE'], // Row 9
    ['netflix', '', '12990', '', '', '', 'FALSE'], // Row 10
    ['BANK Premium ', '', '2495', '', '', '', 'FALSE'], // Row 11
    ['', '', '', '', 'VARIABLE/MANUAL', '', '0'], // Row 12 (delimiter)
    ['tricot', '', '90205', '', '', '', 'TRUE']
  ];

  describe('parsePacSection', () => {
    it('locates AUTOPAY section header and extracts items with 1-based row indices', () => {
      const result = parsePacSection(mockBudgetRows);
      assert.ok(result);
      assert.equal(result.pacItems.length, 5);

      assert.deepEqual(result.pacItems[0], {
        rowIndex: 7,
        concepto: 'robux',
        gasto: 11000,
        pagado: true,
        rawPagado: 'TRUE',
        nota: ''
      });

      assert.deepEqual(result.pacItems[1], {
        rowIndex: 8,
        concepto: 'genshin',
        gasto: 3900,
        pagado: false,
        rawPagado: 'FALSE',
        nota: ''
      });

      assert.equal(result.pacItems[4].concepto, 'BANK Premium');
      assert.equal(result.pacItems[4].rowIndex, 11);
      assert.equal(result.pacItems[4].gasto, 2495);
      assert.equal(result.pacItems[4].pagado, false);

      assert.equal(result.startRowIndex, 6);
      assert.equal(result.endRowIndex, 11);
    });

    it('handles boolean true/false in Pagado column as well as strings', () => {
      const rows = [
        ['', '', '', '', 'AUTOPAY', '', ''],
        ['spotify', '', '4500', '', '', '', true],
        ['crunchyroll', '', '3990', '', '', '', false]
      ];
      const result = parsePacSection(rows);
      assert.equal(result.pacItems.length, 2);
      assert.equal(result.pacItems[0].pagado, true);
      assert.equal(result.pacItems[1].pagado, false);
    });

    it('returns empty pacItems if AUTOPAY header is not found', () => {
      const rows = [
        ['Concepto', 'Ingreso', 'Gasto', 'Columna 1'],
        ['hipotecario', '', '500000', 'FIJO/MANUAL']
      ];
      const result = parsePacSection(rows);
      assert.deepEqual(result.pacItems, []);
      assert.equal(result.startRowIndex, -1);
    });

    it('handles empty input gracefully', () => {
      assert.deepEqual(parsePacSection(null), { pacItems: [], startRowIndex: -1, endRowIndex: -1 });
      assert.deepEqual(parsePacSection([]), { pacItems: [], startRowIndex: -1, endRowIndex: -1 });
    });
  });

  describe('fetchPacSection', () => {
    it('queries Google Sheets values API and returns parsed AUTOPAY items', async () => {
      const mockClient = {
        request: async ({ url }) => {
          assert.ok(url.includes('/values/\'budget\'!A1:G60'));
          return { data: { values: mockBudgetRows } };
        }
      };

      const result = await fetchPacSection(mockClient, DEFAULT_BUDGET_SPREADSHEET_ID, 'budget');
      assert.equal(result.pacItems.length, 5);
      assert.equal(result.pacItems[0].concepto, 'robux');
    });
  });
});
