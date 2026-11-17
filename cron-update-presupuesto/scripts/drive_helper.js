/**
 * drive_helper.js
 * Google Drive file discovery and BANK transaction parsing for cron-update-presupuesto.
 */

const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const crypto = require('node:crypto');

let AuthManager = null;
let authConfig = null;
let extensionLoadAttempted = false;

function loadExtension() {
  if (extensionLoadAttempted) return;
  extensionLoadAttempted = true;
  try {
    ({ AuthManager, authConfig } = require('/home/username/.gemini/extensions/google-workspace/dist/index.js'));
  } catch {
    AuthManager = null;
    authConfig = null;
  }
}

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
    const enc = cipher.update(payload, 'utf8', 'hex') + cipher.final('hex');
    const tag = cipher.getAuthTag();
    fs.writeFileSync(tokenFile, `${iv.toString('hex')}:${tag.toString('hex')}:${enc}`, { mode: 0o600 });
    return true;
  } catch {
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
 * Normalizes and parses Chilean Peso amounts into numeric integers.
 * E.g., '22,990' -> 22990, '$1,000,000' -> 1000000, ' 15.500 ' -> 15500.
 */
function parseTransactionAmount(val) {
  if (typeof val === 'number') {
    return isNaN(val) ? 0 : Math.round(val);
  }
  if (!val) return 0;
  const str = String(val).replace(/[$]/g, '').trim();
  const digitsOnly = str.replace(/[.,\s]/g, '');
  const parsed = parseInt(digitsOnly, 10);
  return isNaN(parsed) ? 0 : parsed;
}

/**
 * Parses raw 2D sheet rows from a BANK statement spreadsheet into structured transaction objects.
 */
function parseMachTransactions(rows) {
  if (!Array.isArray(rows) || rows.length <= 1) return [];

  const transactions = [];
  for (let i = 1; i < rows.length; i++) {
    const row = rows[i];
    if (!Array.isArray(row) || row.length === 0) continue;

    const date = (row[0] || '').trim();
    const merchant = (row[1] || '').trim();
    const category = (row[2] || '').trim();
    const rawAmount = String(row[3] !== undefined && row[3] !== null ? row[3] : '').trim();
    const timestamp = (row[4] || '').trim();

    if (!merchant && !rawAmount) continue;

    transactions.push({
      date,
      merchant,
      category,
      amount: parseTransactionAmount(rawAmount),
      timestamp,
      rawAmount
    });
  }

  return transactions;
}

/**
 * Finds the current month's BANK spreadsheet in the specified Drive folder.
 * Falls back to the latest modified file if exact match is not found.
 */
async function findCurrentMonthMachFile(client, folderId, options = {}) {
  const targetDate = options.targetDate || new Date();
  const year = targetDate.getFullYear();
  const month = String(targetDate.getMonth() + 1).padStart(2, '0');
  const targetName = `BANK_${year}.${month}`;

  const res = await client.request({
    url: `https://www.googleapis.com/drive/v3/files?q='${folderId}'+in+parents+and+trashed=false&fields=files(id,name,modifiedTime)&orderBy=modifiedTime+desc`
  });

  const files = res.data?.files || [];
  if (files.length === 0) return null;

  const exact = files.find(f => f.name && f.name.includes(targetName));
  return exact || files[0];
}

/**
 * Fetches transactions from a BANK statement spreadsheet.
 */
async function fetchMachTransactions(client, fileId) {
  const meta = await client.request({
    url: `https://sheets.googleapis.com/v4/spreadsheets/${fileId}`
  });

  const sheetTitle = meta.data?.sheets?.[0]?.properties?.title || 'Sheet1';
  const res = await client.request({
    url: `https://sheets.googleapis.com/v4/spreadsheets/${fileId}/values/'${sheetTitle}'!A:E`
  });

  return parseMachTransactions(res.data?.values || []);
}

module.exports = {
  getGoogleClient,
  ensureTokenFileSync,
  parseTransactionAmount,
  parseMachTransactions,
  findCurrentMonthMachFile,
  fetchMachTransactions
};
