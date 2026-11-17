const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

// Import helpers (will fail in RED phase until implemented)
const {
  insertRowAtTop,
  updateLiquidation,
  fetchSpreadsheetRows,
  findRowBySolicitud,
  normalizeSolicitud
} = require('../scripts/sheets_helper.js');

describe('Google Sheets Helper', () => {
  describe('normalizeSolicitud', () => {
    it('normalizes string with commas and decimals', () => {
      assert.equal(normalizeSolicitud('341,034.00'), '341034');
      assert.equal(normalizeSolicitud('341.034'), '341034');
      assert.equal(normalizeSolicitud(' 341034 '), '341034');
      assert.equal(normalizeSolicitud(341034), '341034');
    });

    it('returns empty string for null or undefined', () => {
      assert.equal(normalizeSolicitud(null), '');
      assert.equal(normalizeSolicitud(undefined), '');
    });
  });

  describe('findRowBySolicitud', () => {
    const mockRows = [
      ['Nº Solicitud', 'Beneficiario', 'Valor Reclamado', 'Devolución', 'Estado', 'Item', 'Fecha Liquidacion'],
      ['341,034.00', 'Juan Perez', '50000', '', 'Denunciado', 'specialist_a', ''],
      ['339814', 'Beneficiary Sample', '30000', '15000', 'Liquidado', 'medicamentos', '09-10-2026']
    ];

    it('finds existing solicitud and returns 1-based sheet row index and data', () => {
      const match = findRowBySolicitud(mockRows, '341034');
      assert.ok(match, 'Expected match to be found');
      assert.equal(match.rowIndex, 2);
      assert.equal(match.rowData[0], '341,034.00');
    });

    it('returns null when solicitud is not in the rows', () => {
      const match = findRowBySolicitud(mockRows, '999999');
      assert.equal(match, null);
    });
  });

  describe('insertRowAtTop', () => {
    it('sends insertDimension batchUpdate request followed by values update to row 2', async () => {
      const requestsMade = [];
      const mockClient = {
        request: async (opts) => {
          requestsMade.push(opts);
          if (opts.url.includes(':batchUpdate')) {
            return { data: { replies: [{ insertDimension: {} }] } };
          }
          if (opts.url.includes('/values/')) {
            return { data: { updatedRows: 1 } };
          }
          return { data: {} };
        }
      };

      const rowValues = ['341035', '', '', '', 'Denunciado', 'plantillas', ''];
      const result = await insertRowAtTop(mockClient, 'mock-sheet-id', 0, rowValues);

      assert.equal(requestsMade.length, 2);
      // First request: insertDimension
      assert.equal(requestsMade[0].method, 'POST');
      assert.match(requestsMade[0].url, /spreadsheets\/mock-sheet-id:batchUpdate/);
      assert.deepEqual(requestsMade[0].data.requests[0].insertDimension, {
        range: {
          sheetId: 0,
          dimension: 'ROWS',
          startIndex: 1,
          endIndex: 2
        },
        inheritFromBefore: false
      });

      // Second request: values PUT
      assert.equal(requestsMade[1].method, 'PUT');
      assert.match(requestsMade[1].url, /Insurance%20seguro%20V4!A2:G2/);
      assert.deepEqual(requestsMade[1].data.values, [rowValues]);
      assert.equal(result.success, true);
    });
  });

  describe('updateLiquidation', () => {
    it('sends batchUpdate values request updating columns D, E, G for the given rowIndex', async () => {
      const requestsMade = [];
      const mockClient = {
        request: async (opts) => {
          requestsMade.push(opts);
          return { data: { responses: [] } };
        }
      };

      const result = await updateLiquidation(mockClient, 'mock-sheet-id', 5, 'Liquidado', 4392, '09-10-2026');

      assert.equal(requestsMade.length, 1);
      assert.equal(requestsMade[0].method, 'POST');
      assert.match(requestsMade[0].url, /spreadsheets\/mock-sheet-id\/values:batchUpdate/);
      assert.equal(requestsMade[0].data.valueInputOption, 'USER_ENTERED');
      assert.deepEqual(requestsMade[0].data.data, [
        { range: 'Insurance Tracker!D5', values: [[4392]] },
        { range: 'Insurance Tracker!E5', values: [['Liquidado']] },
        { range: 'Insurance Tracker!G5', values: [['09-10-2026']] }
      ]);
      assert.equal(result.success, true);
    });
  });

  describe('fetchSpreadsheetRows', () => {
    it('calls GET on spreadsheet values range and returns rows array', async () => {
      const mockClient = {
        request: async (opts) => {
          assert.equal(opts.method, 'GET');
          assert.match(opts.url, /Insurance%20seguro%20V4!A:G/);
          return {
            data: {
              values: [
                ['Nº Solicitud', 'Beneficiario'],
                ['341034', 'Juan']
              ]
            }
          };
        }
      };

      const rows = await fetchSpreadsheetRows(mockClient, 'mock-sheet-id', 'Insurance Tracker!A:G');
      assert.equal(rows.length, 2);
      assert.equal(rows[1][0], '341034');
    });
  });

  describe('getGoogleClient & Headless Storage', () => {
    it('initializes and returns an authenticated client when extension is present', async () => {
      const { getGoogleClient } = require('../scripts/sheets_helper.js');
      const client = await getGoogleClient();
      assert.ok(client);
      assert.equal(typeof client.request, 'function');
    });

    it('ensures headless file storage token sync is callable and returns true', async () => {
      const { ensureTokenFileSync } = require('../scripts/sheets_helper.js');
      assert.equal(typeof ensureTokenFileSync, 'function', 'ensureTokenFileSync should be exported');
      const synced = await ensureTokenFileSync();
      assert.ok(synced, 'ensureTokenFileSync should succeed');
    });

    it('authenticates successfully in headless mode with GEMINI_CLI_WORKSPACE_FORCE_FILE_STORAGE=true', async () => {
      const originalEnv = process.env.GEMINI_CLI_WORKSPACE_FORCE_FILE_STORAGE;
      try {
        process.env.GEMINI_CLI_WORKSPACE_FORCE_FILE_STORAGE = 'true';
        const { getGoogleClient } = require('../scripts/sheets_helper.js');
        const client = await getGoogleClient();
        assert.ok(client);
        assert.equal(typeof client.request, 'function');
      } finally {
        if (originalEnv !== undefined) {
          process.env.GEMINI_CLI_WORKSPACE_FORCE_FILE_STORAGE = originalEnv;
        } else {
          delete process.env.GEMINI_CLI_WORKSPACE_FORCE_FILE_STORAGE;
        }
      }
    });
  });
});

