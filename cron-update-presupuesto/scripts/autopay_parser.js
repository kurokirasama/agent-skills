/**
 * autopay_parser.js
 * Scans and extracts AUTOPAY items from the 'budget' tab of the target spreadsheet.
 */

const { parseTransactionAmount } = require('./drive_helper.js');

const DEFAULT_BUDGET_SPREADSHEET_ID = '<GOOGLE_SHEET_ID>';
const DEFAULT_BUDGET_TAB = 'budget';

/**
 * Parses raw rows from the 'budget' tab to locate and extract items in the AUTOPAY section.
 *
 * @param {Array<Array<any>>} rows 2D array of spreadsheet values.
 * @returns {{ pacItems: Array<object>, startRowIndex: number, endRowIndex: number }}
 */
function parsePacSection(rows) {
  if (!Array.isArray(rows) || rows.length === 0) {
    return { pacItems: [], startRowIndex: -1, endRowIndex: -1 };
  }

  let inPac = false;
  let startRowIndex = -1;
  let endRowIndex = -1;
  const pacItems = [];

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i] || [];
    const colE = String(row[4] !== undefined && row[4] !== null ? row[4] : '').trim();
    const concepto = String(row[0] !== undefined && row[0] !== null ? row[0] : '').trim();
    const rawGasto = row[2];
    const rawPagado = row[6];
    const nota = String(row[5] !== undefined && row[5] !== null ? row[5] : '').trim();

    if (colE.toUpperCase() === 'AUTOPAY') {
      inPac = true;
      startRowIndex = i + 1; // 1-based index
      continue;
    }

    if (inPac) {
      // Reached next section delimiter (e.g. VARIABLE/MANUAL, COMPRAS/GASTOS, etc.)
      if (colE && colE.toUpperCase() !== 'AUTOPAY') {
        endRowIndex = i; // Last row belonging to AUTOPAY section was i
        break;
      }

      if (concepto) {
        const pagado = typeof rawPagado === 'boolean'
          ? rawPagado
          : String(rawPagado || '').trim().toUpperCase() === 'TRUE';

        pacItems.push({
          rowIndex: i + 1, // 1-based index for Google Sheets
          concepto,
          gasto: parseTransactionAmount(rawGasto),
          pagado,
          rawPagado: rawPagado !== undefined && rawPagado !== null ? String(rawPagado).trim() : '',
          nota
        });
        endRowIndex = i + 1;
      }
    }
  }

  if (!inPac) {
    return { pacItems: [], startRowIndex: -1, endRowIndex: -1 };
  }

  return {
    pacItems,
    startRowIndex,
    endRowIndex
  };
}

/**
 * Fetches the 'budget' tab rows and parses the AUTOPAY section.
 *
 * @param {object} client Authenticated Google Workspace client.
 * @param {string} [spreadsheetId] Target spreadsheet ID.
 * @param {string} [tabName] Target tab name.
 */
async function fetchPacSection(client, spreadsheetId = DEFAULT_BUDGET_SPREADSHEET_ID, tabName = DEFAULT_BUDGET_TAB) {
  const res = await client.request({
    url: `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}/values/'${tabName}'!A1:G60`
  });

  return parsePacSection(res.data?.values || []);
}

module.exports = {
  DEFAULT_BUDGET_SPREADSHEET_ID,
  DEFAULT_BUDGET_TAB,
  parsePacSection,
  fetchPacSection
};
