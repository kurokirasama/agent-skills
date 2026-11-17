/**
 * gmail_label_manager.js
 * Gmail API helper for label management, message search, and thread evaluation.
 */

const DEFAULT_LABEL_NAME = 'seguro/procesado';
const ALL_INSURANCE_QUERY = '(from:support@insurance.example.com OR from:support@insurance.example.com OR subject:"Claim Notice" OR subject:"Settlement Notice")';
const DEFAULT_SEARCH_QUERY = `${ALL_INSURANCE_QUERY} -label:seguro/procesado`;

/**
 * Checks if label exists in Gmail; creates it if missing.
 * Returns the label ID.
 */
async function ensureLabelExists(client, labelName = DEFAULT_LABEL_NAME) {
  const listRes = await client.request({
    url: 'https://gmail.googleapis.com/gmail/v1/users/me/labels',
    method: 'GET'
  });

  const labels = listRes.data?.labels || [];
  const existing = labels.find((l) => l.name === labelName);
  if (existing) {
    return existing.id;
  }

  // Create label
  const createRes = await client.request({
    url: 'https://gmail.googleapis.com/gmail/v1/users/me/labels',
    method: 'POST',
    data: {
      name: labelName,
      labelListVisibility: 'labelShow',
      messageListVisibility: 'show'
    }
  });

  return createRes.data?.id;
}

/**
 * Modifies an individual message: adds labelId and removes 'UNREAD'.
 */
async function applyLabelAndMarkRead(client, messageId, labelId) {
  await client.request({
    url: `https://gmail.googleapis.com/gmail/v1/users/me/messages/${encodeURIComponent(messageId)}/modify`,
    method: 'POST',
    data: {
      addLabelIds: [labelId],
      removeLabelIds: ['UNREAD']
    }
  });

  return { success: true, messageId, labelId };
}

/**
 * Searches messages matching a query string.
 * Returns an array of { id, threadId }.
 */
async function searchUnprocessedMessages(client, query = DEFAULT_SEARCH_QUERY) {
  const messages = [];
  let pageToken = null;

  do {
    const params = new URLSearchParams({ q: query, maxResults: '100' });
    if (pageToken) params.set('pageToken', pageToken);

    const response = await client.request({
      url: `https://gmail.googleapis.com/gmail/v1/users/me/messages?${params.toString()}`,
      method: 'GET'
    });

    const data = response.data || {};
    messages.push(...(data.messages || []));
    pageToken = data.nextPageToken || null;
  } while (pageToken);

  // Defensive dedup: the same message id must never be processed twice
  const seen = new Set();
  return messages.filter((m) => {
    if (!m || !m.id || seen.has(m.id)) return false;
    seen.add(m.id);
    return true;
  });
}

/**
 * Fetches full message details by message ID (headers, payload, parts).
 */
async function getMessageDetails(client, messageId) {
  const response = await client.request({
    url: `https://gmail.googleapis.com/gmail/v1/users/me/messages/${encodeURIComponent(messageId)}?format=full`,
    method: 'GET'
  });

  return response.data;
}

/**
 * Recursively locates the first PDF part carrying an attachment id.
 */
function findPdfPart(payload) {
  if (!payload) return null;
  const parts = payload.parts || [];
  for (const part of parts) {
    if (part.filename && /\.pdf$/i.test(part.filename) && part.body && part.body.attachmentId) {
      return part;
    }
    const nested = findPdfPart(part);
    if (nested) return nested;
  }
  return null;
}

/**
 * Downloads the PDF attachment of a message (if any) and returns its bytes.
 * INSURANCE sends the PDF with mimeType application/octet-stream, so match on filename.
 */
async function downloadPdfAttachment(client, messageId, payload) {
  const part = findPdfPart(payload);
  if (!part) return null;

  const response = await client.request({
    url: `https://gmail.googleapis.com/gmail/v1/users/me/messages/${encodeURIComponent(messageId)}/attachments/${encodeURIComponent(part.body.attachmentId)}`,
    method: 'GET'
  });

  const raw = response.data && response.data.data ? response.data.data : '';
  if (!raw) return null;
  const base64 = raw.replace(/-/g, '+').replace(/_/g, '/');
  return Buffer.from(base64, 'base64');
}

module.exports = {
  DEFAULT_LABEL_NAME,
  ALL_INSURANCE_QUERY,
  DEFAULT_SEARCH_QUERY,
  ensureLabelExists,
  applyLabelAndMarkRead,
  searchUnprocessedMessages,
  getMessageDetails,
  downloadPdfAttachment
};
