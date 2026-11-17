/**
 * sheets_helper.js
 * Google Sheets API helper for Seguro updates.
 */

let AuthManager = null;
let authConfig = null;
let extensionLoadAttempted = false;

// Lazy-load the Google Workspace extension only when a real client is needed.
// Requiring the bundled dist at module load starts a stdio MCP server on machines
// where the module guard patch is absent, which hangs test runs.
function loadExtension() {
  if (extensionLoadAttempted) return;
  extensionLoadAttempted = true;
  try {
    ({ AuthManager, authConfig } = require('/home/username/.gemini/extensions/google-workspace/dist/index.js'));
  } catch {
    // Fallback if imported in isolated test environments
    AuthManager = null;
    authConfig = null;
  }
}

const DEFAULT_SPREADSHEET_ID = '<GOOGLE_SHEET_ID>';
const SHEET_TAB_NAME = 'Insurance Tracker';

const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const crypto = require('node:crypto');

async function ensureTokenFileSync() {
  const tokenFile = '/home/username/.gemini/extensions/google-workspace/gemini-cli-workspace-token.json';
  if (fs.existsSync(tokenFile)) return true;

  try {
    const keytarPath = '/home/username/.gemini/extensions/google-workspace/node_modules/keytar';
    if (!fs.existsSync(keytarPath)) return false;
    const keytar = require(keytarPath);
    const creds = await keytar.findCredentials('gemini-cli-workspace-oauth');
    const main = creds.find(c => c.account === 'main-account');
    if (!main) return false;

    const masterKeyFile = '/home/username/.gemini/extensions/google-workspace/.gemini-cli-workspace-master-key';
    if (!fs.existsSync(masterKeyFile)) return false;

    const masterKey = fs.readFileSync(masterKeyFile);
    const salt = `${os.hostname()}-${os.userInfo().username}-gemini-cli-workspace`;
    const encKey = crypto.scryptSync(masterKey, salt, 32);

    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-gcm', encKey, iv);
    const payload = JSON.stringify({ 'main-account': JSON.parse(main.password) }, null, 2);
    let enc = cipher.update(payload, 'utf8', 'hex') + cipher.final('hex');
    const tag = cipher.getAuthTag();
    fs.writeFileSync(tokenFile, `${iv.toString('hex')}:${tag.toString('hex')}:${enc}`, { mode: 0o600 });
    return true;
  } catch (err) {
    return false;
  }
}

async function getGoogleClient() {
  loadExtension();
  if (!AuthManager || !authConfig) {
    throw new Error('Google Workspace extension not available at /home/username/.gemini/extensions/google-workspace/dist/index.js');
  }
  if (process.env.GEMINI_CLI_WORKSPACE_FORCE_FILE_STORAGE === 'true') {
    await ensureTokenFileSync();
  }
  const auth = new AuthManager(authConfig);
  return await auth.getAuthenticatedClient();
}

/**
 * Normalizes a claim / solicitud ID by removing commas, decimals, spaces, and non-numeric characters.
 * Example: '341,034.00' -> '341034', '341.034' -> '341034'
 */
function normalizeSolicitud(val) {
  if (val === null || val === undefined) return '';
  const str = String(val).trim();
  // If format is like '341,034.00', drop the decimal part first if .00
  const noDecimals = str.replace(/\.00$/, '').replace(/,00$/, '');
  // Remove all commas, dots, and spaces
  return noDecimals.replace(/[.,\s]/g, '');
}

/**
 * Finds a row by solicitud ID in a 2D array of rows from Google Sheets.
 * Returns { rowIndex: number, rowData: Array } where rowIndex is 1-based sheet row index, or null.
 */
function findRowBySolicitud(rows, solicitudId) {
  if (!Array.isArray(rows) || !solicitudId) return null;
  const target = normalizeSolicitud(solicitudId);
  if (!target) return null;

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    if (Array.isArray(row) && row.length > 0) {
      const cellVal = normalizeSolicitud(row[0]);
      if (cellVal === target) {
        return {
          rowIndex: i + 1, // 1-based index in Google Sheets
          rowData: row
        };
      }
    }
  }
  return null;
}

/**
 * Fetches rows from a sheet range.
 */
async function fetchSpreadsheetRows(client, spreadsheetId = DEFAULT_SPREADSHEET_ID, range = `${SHEET_TAB_NAME}!A:G`) {
  const encodedRange = encodeURI(range);
  const response = await client.request({
    url: `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}/values/${encodedRange}`,
    method: 'GET'
  });
  return response.data?.values || [];
}

/**
 * Resolves the numeric grid id for the target tab. Grid ids are NOT stable
 * across spreadsheets (0 is only valid on the first sheet ever created).
 */
async function resolveSheetId(client, spreadsheetId = DEFAULT_SPREADSHEET_ID, tabName = SHEET_TAB_NAME) {
  const response = await client.request({
    url: `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}?fields=sheets.properties(sheetId,title)`,
    method: 'GET'
  });
  const sheets = response.data?.sheets || [];
  const match = sheets.find((s) => s.properties?.title === tabName);
  if (!match) {
    throw new Error(`Tab "${tabName}" not found in spreadsheet ${spreadsheetId}`);
  }
  return match.properties.sheetId;
}

/**
 * Shifts existing rows down by inserting an empty dimension at index 1 (Row 2),
 * then populates Row 2 with rowValues.
 */
async function insertRowAtTop(client, spreadsheetId = DEFAULT_SPREADSHEET_ID, sheetId = null, rowValues = []) {
  if (sheetId === null || sheetId === undefined) {
    sheetId = await resolveSheetId(client, spreadsheetId);
  }

  // 1. Insert row dimension directly beneath header (index 1 to 2)
  await client.request({
    url: `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}:batchUpdate`,
    method: 'POST',
    data: {
      requests: [
        {
          insertDimension: {
            range: {
              sheetId: sheetId,
              dimension: 'ROWS',
              startIndex: 1,
              endIndex: 2
            },
            inheritFromBefore: false
          }
        }
      ]
    }
  });

  // 2. Populate row 2
  const rangeName = `${SHEET_TAB_NAME}!A2:G2`;
  await client.request({
    url: `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}/values/${encodeURI(rangeName)}?valueInputOption=USER_ENTERED`,
    method: 'PUT',
    data: {
      range: rangeName,
      majorDimension: 'ROWS',
      values: [rowValues]
    }
  });

  return { success: true, updatedRange: rangeName };
}

/**
 * Updates columns D (Devolución), E (Estado), G (Fecha Liquidacion) for an existing row.
 */
async function updateLiquidation(client, spreadsheetId = DEFAULT_SPREADSHEET_ID, rowIndex, estado, devolucion = '', fechaLiquidacion = '') {
  const updates = [
    {
      range: `${SHEET_TAB_NAME}!D${rowIndex}`,
      values: [[devolucion !== undefined && devolucion !== null ? devolucion : '']]
    },
    {
      range: `${SHEET_TAB_NAME}!E${rowIndex}`,
      values: [[estado]]
    },
    {
      range: `${SHEET_TAB_NAME}!G${rowIndex}`,
      values: [[fechaLiquidacion || '']]
    }
  ];

  await client.request({
    url: `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}/values:batchUpdate`,
    method: 'POST',
    data: {
      valueInputOption: 'USER_ENTERED',
      data: updates
    }
  });

  return { success: true, rowIndex };
}

/**
 * Normalizes a person name for order-insensitive comparison (accents/case/punctuation-insensitive).
 */
function normalizeName(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .filter(Boolean)
    .sort()
    .join(' ');
}

/**
 * Normalizes an amount for numeric comparison (strips thousands separators and symbols).
 */
function normalizeNumber(value) {
  return String(value ?? '').replace(/[^\d]/g, '');
}

/**
 * Reconciles target cells against authoritative values (liquidation PDF).
 * Beneficiario (B) compares as an order-insensitive token set; Valor Reclamado (C)
 * compares numerically; Item (F) is only filled when empty. Empty incoming values are
 * never written. Returns { updated, changes: [{ column, from, to }] }.
 */
async function reconcileRowFields(client, spreadsheetId = DEFAULT_SPREADSHEET_ID, rowIndex, rowValues = [], cellsByColumn = {}) {
  const columnIndex = { A: 0, B: 1, C: 2, D: 3, E: 4, F: 5, G: 6 };
  const updates = [];
  const changes = [];

  for (const [column, value] of Object.entries(cellsByColumn)) {
    if (value === '' || value === null || value === undefined) continue;
    const idx = columnIndex[column];
    if (idx === undefined) continue;

    const current = Array.isArray(rowValues) ? rowValues[idx] : undefined;
    const currentStr = current === undefined || current === null ? '' : String(current).trim();
    const nextStr = String(value).trim();

    if (column === 'B') {
      if (normalizeName(currentStr) === normalizeName(nextStr)) continue;
    } else if (column === 'C') {
      if (normalizeNumber(currentStr) === normalizeNumber(nextStr)) continue;
    } else if (column === 'F') {
      if (currentStr !== '') continue; // fill-only: the item category may be a manual label
    } else if (currentStr === nextStr) {
      continue;
    }

    updates.push({
      range: `'${SHEET_TAB_NAME}'!${column}${rowIndex}`,
      values: [[value]]
    });
    changes.push({ column, from: currentStr, to: value });
  }

  if (updates.length === 0) return { updated: false, changes: [] };

  await client.request({
    url: `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}/values:batchUpdate`,
    method: 'POST',
    data: {
      valueInputOption: 'USER_ENTERED',
      data: updates
    }
  });

  return { updated: true, changes };
}

module.exports = {
  DEFAULT_SPREADSHEET_ID,
  SHEET_TAB_NAME,
  getGoogleClient,
  ensureTokenFileSync,
  normalizeSolicitud,
  findRowBySolicitud,
  fetchSpreadsheetRows,
  resolveSheetId,
  insertRowAtTop,
  updateLiquidation,
  reconcileRowFields
};
