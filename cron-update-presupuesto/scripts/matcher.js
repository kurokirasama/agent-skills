/**
 * matcher.js
 * Smart transaction matching and Google Sheets checkbox updating engine.
 */

const ALIAS_MAP = {
  'robux': ['roblox', 'robux'],
  'genshin': ['genshin', 'cognosphere', 'mihoyo'],
  'youtube': ['youtube', 'google*youtube'],
  'yoosee': ['yoosee', 'yoosee app'],
  'uber': ['uber', 'uber *trip', 'uber eats'],
  'disney+': ['disney', 'disney+', 'disney plus'],
  'netflix': ['netflix'],
  'bank premium': ['bank premium', 'bank subscription'],
  'prime video': ['prime video', 'amazon prime', 'amazon video'],
  'ai apis': ['openai', 'anthropic', 'gemini', 'opencode', 'ai apis'],
  'google ai pro': ['google *google one', 'google ai', 'google workspace', 'google ai pro']
};

/**
 * Normalizes an item concept key for dictionary lookup.
 */
function normalizeConceptKey(concepto) {
  if (!concepto) return '';
  return String(concepto).toLowerCase().trim();
}

/**
 * Checks if a transaction amount matches the budgeted AUTOPAY amount within allowable tolerance.
 * Allows up to 15% variance (currency conversion) or up to $2,000 Chilean Pesos difference.
 */
function isAmountWithinTolerance(budgetAmount, txAmount) {
  if (budgetAmount <= 0 || txAmount <= 0) return true;
  const absDiff = Math.abs(budgetAmount - txAmount);
  const relDiff = absDiff / budgetAmount;
  return relDiff <= 0.15 || absDiff <= 2000;
}

/**
 * Matches a single AUTOPAY item against an array of transactions.
 * Returns the matched transaction or null.
 */
function matchSinglePacItem(pacItem, transactions) {
  if (!pacItem || !Array.isArray(transactions) || transactions.length === 0) return null;

  const key = normalizeConceptKey(pacItem.concepto);
  const aliases = ALIAS_MAP[key] || [key];

  return transactions.find(t => {
    if (!t || !t.merchant) return false;
    const merchant = String(t.merchant).toLowerCase();
    const aliasMatched = aliases.some(alias => merchant.includes(alias.toLowerCase()));
    if (!aliasMatched) return false;

    return isAmountWithinTolerance(pacItem.gasto || 0, t.amount || 0);
  }) || null;
}

/**
 * Evaluates all AUTOPAY items against transactions, categorizing each into:
 * - 'ALREADY_PAID': already checked in the spreadsheet.
 * - 'NEWLY_PAID': unchecked in spreadsheet, but a matching transaction was found.
 * - 'PENDING': unchecked in spreadsheet and no transaction found.
 *
 * @returns {Array<{ pacItem: object, matchedTransaction: object|null, status: string }>}
 */
function matchPacTransactions(pacItems, transactions) {
  if (!Array.isArray(pacItems)) return [];
  const txList = Array.isArray(transactions) ? transactions : [];

  return pacItems.map(pacItem => {
    const matchedTransaction = matchSinglePacItem(pacItem, txList);

    let status = 'PENDING';
    if (pacItem.pagado) {
      status = 'ALREADY_PAID';
    } else if (matchedTransaction) {
      status = 'NEWLY_PAID';
    }

    return {
      pacItem,
      matchedTransaction,
      status
    };
  });
}

/**
 * Generates Google Sheets batch update ranges and boolean payloads for NEWLY_PAID items.
 */
function generateCheckboxUpdates(matches, tabName = 'budget') {
  if (!Array.isArray(matches)) return [];

  return matches
    .filter(m => m.status === 'NEWLY_PAID' && m.pacItem && m.pacItem.rowIndex > 0)
    .sort((a, b) => a.pacItem.rowIndex - b.pacItem.rowIndex)
    .map(m => ({
      range: `'${tabName}'!G${m.pacItem.rowIndex}`,
      values: [[true]]
    }));
}

/**
 * Sends a batch update to mark multiple AUTOPAY rows as paid in Google Sheets.
 */
async function updatePacCheckboxes(client, spreadsheetId, updates) {
  if (!Array.isArray(updates) || updates.length === 0) {
    return { updatedCount: 0, updatedRows: [] };
  }

  const res = await client.request({
    url: `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}/values:batchUpdate`,
    method: 'POST',
    data: {
      valueInputOption: 'USER_ENTERED',
      data: updates
    }
  });

  return {
    updatedCount: updates.length,
    updatedRows: updates.map(u => u.range),
    apiResponse: res.data
  };
}

/**
 * Updates a single AUTOPAY row's Pagado checkbox to TRUE in Google Sheets.
 */
async function markPacRowPaid(client, spreadsheetId, rowIndex, tabName = 'budget') {
  const range = `'${tabName}'!G${rowIndex}`;
  const res = await client.request({
    url: `https://sheets.googleapis.com/v4/spreadsheets/${spreadsheetId}/values/${range}?valueInputOption=USER_ENTERED`,
    method: 'PUT',
    data: {
      range,
      majorDimension: 'ROWS',
      values: [[true]]
    }
  });

  return res.data;
}

module.exports = {
  ALIAS_MAP,
  normalizeConceptKey,
  isAmountWithinTolerance,
  matchSinglePacItem,
  matchPacTransactions,
  generateCheckboxUpdates,
  updatePacCheckboxes,
  markPacRowPaid
};
