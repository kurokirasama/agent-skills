/**
 * parser.js
 * Core parsing engine for INSURANCE denuncio notifications, liquidation emails,
 * and medical item prediction.
 */

const VOCABULARY = [
  'eval plantillas',
  'plantillas',
  'med specialist',
  'specialist_a',
  'treatment_a',
  'therapy_a',
  'compounded',
  'test cutaneo',
  'alergia',
  'medicamentos',
  'derma',
  'peg',
  'specialist_b2',
  'specialist_b'
];

/**
 * Extracts a specific header by name (case-insensitive).
 */
function extractHeader(headers = [], name = '') {
  if (!Array.isArray(headers)) return '';
  const target = name.toLowerCase();
  const found = headers.find((h) => h.name && h.name.toLowerCase() === target);
  return found ? found.value : '';
}

/**
 * Recursively extracts plain/HTML text from a Gmail message payload.
 */
function extractBodyText(payload) {
  if (!payload) return '';
  let text = '';

  if (payload.body && payload.body.data) {
    // Decode base64 / URL-safe base64
    const base64 = payload.body.data.replace(/-/g, '+').replace(/_/g, '/');
    try {
      text += Buffer.from(base64, 'base64').toString('utf8');
    } catch {
      // Ignore decoding failure on corrupt body part
    }
  }

  if (Array.isArray(payload.parts)) {
    for (const part of payload.parts) {
      text += extractBodyText(part);
    }
  }

  return text;
}

/**
 * Formats a raw solicitud ID (e.g. 341034) into the spreadsheet style (e.g. '341,034.00').
 */
function formatSolicitudForSheet(solicitudId) {
  if (solicitudId === null || solicitudId === undefined) return '';
  const clean = String(solicitudId).replace(/[^\d]/g, '');
  if (!clean) return '';
  const num = Number(clean);
  if (Number.isNaN(num)) return '';
  return num.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
}

/**
 * Classifies an incoming message into 'DENUNCIO', 'LIQUIDACION', or 'UNKNOWN'.
 */
function classifyMessage(messageDetails) {
  if (!messageDetails || !messageDetails.payload) return 'UNKNOWN';

  const headers = messageDetails.payload.headers || [];
  const subject = extractHeader(headers, 'Subject');
  const bodyText = extractBodyText(messageDetails.payload);

  if (/Claim Notice/i.test(subject) || /se ha ingresado la denuncia/i.test(bodyText)) {
    return 'DENUNCIO';
  }

  if (
    /Settlement Notice/i.test(subject) ||
    /informe de liquidacion/i.test(bodyText) ||
    (messageDetails.payload.parts &&
      messageDetails.payload.parts.some((p) => /.*-(\d{5,7})\.pdf/i.test(p.filename || '')))
  ) {
    return 'LIQUIDACION';
  }

  return 'UNKNOWN';
}

/**
 * Parses a 'Claim Notice' message.
 * Extracts solicitud ID, denuncio date, and constructs a row for Insurance Tracker.
 */
function parseDenuncio(messageDetails, predictedItem = '') {
  const headers = messageDetails.payload?.headers || [];
  const subject = extractHeader(headers, 'Subject');
  const bodyText = extractBodyText(messageDetails.payload);

  // 1. Solicitud ID
  let solicitud = '';
  const subjectMatch = subject.match(/Claim Notice\s+(\d+)/i);
  if (subjectMatch) {
    solicitud = subjectMatch[1];
  } else {
    const bodyMatch = bodyText.match(/denuncia\s+N[°º\s]*(\d+)/i) || bodyText.match(/solicitud[:\s]*(\d+)/i);
    if (bodyMatch) {
      solicitud = bodyMatch[1];
    }
  }

  // 2. Date
  let denuncioDate = '';
  const dateMatch = bodyText.match(/con fecha\s+(\d{2}-\d{2}-\d{4})/i);
  if (dateMatch) {
    denuncioDate = dateMatch[1];
  } else {
    const rawDateHeader = extractHeader(headers, 'Date');
    if (rawDateHeader) {
      const d = new Date(rawDateHeader);
      if (!Number.isNaN(d.getTime())) {
        const dd = String(d.getDate()).padStart(2, '0');
        const mm = String(d.getMonth() + 1).padStart(2, '0');
        const yyyy = d.getFullYear();
        denuncioDate = `${dd}-${mm}-${yyyy}`;
      }
    }
  }

  // 3. Beneficiario
  let beneficiario = '';
  const beneMatch = bodyText.match(/Estimado\(a\)\s*(?:<strong>)?([^<:\n]+?)(?:<\/strong>)?(?:<[^>]*>|[:\n]|\s+Junto)/i);
  if (beneMatch) {
    beneficiario = beneMatch[1].replace(/\s+/g, ' ').trim();
  }

  const formattedSolicitud = formatSolicitudForSheet(solicitud);

  // Sheet Row: [Nº Solicitud, Beneficiario, Valor Reclamado, Devolución, Estado, Item, Fecha Liquidacion]
  const sheetRow = [
    formattedSolicitud,
    beneficiario, // Beneficiario from the email body
    '', // Valor Reclamado blank until the liquidation PDF arrives
    '', // Devolución empty
    'Denunciado',
    predictedItem || '',
    '' // Fecha Liquidacion empty
  ];

  return {
    solicitud,
    formattedSolicitud,
    denuncioDate,
    beneficiario,
    estado: 'Denunciado',
    item: predictedItem,
    sheetRow
  };
}

/**
 * Parses an 'Settlement Notice' message.
 * Extracts solicitud ID, liquidation date, approval vs rejection status, and payment amount.
 */
function parseLiquidacion(messageDetails) {
  const headers = messageDetails.payload?.headers || [];
  const subject = extractHeader(headers, 'Subject');
  const bodyText = extractBodyText(messageDetails.payload);
  const parts = messageDetails.payload?.parts || [];

  // 1. Solicitud ID from attachment filename, subject, or body
  let solicitud = '';
  for (const part of parts) {
    const match = (part.filename || '').match(/(?:-\s*|\s+)(\d{5,7})\.pdf$/i);
    if (match) {
      solicitud = match[1];
      break;
    }
  }

  if (!solicitud) {
    const subjMatch = subject.match(/(?:-\s*|\s+)(\d{5,7})\.pdf/i) || subject.match(/-\s*(\d{5,7})\b/i);
    if (subjMatch) {
      solicitud = subjMatch[1];
    } else {
      const allMatches = [...subject.matchAll(/\b(\d{5,7})\b/g)];
      if (allMatches.length > 0) {
        solicitud = allMatches[allMatches.length - 1][1];
      }
    }
  }

  // 2. Fecha Liquidacion
  let fechaLiquidacion = '';
  const dateMatch = bodyText.match(/procesada con fecha\s*(\d{2}-\d{2}-\d{4})/i);
  if (dateMatch) {
    fechaLiquidacion = dateMatch[1];
  }

  // 3. Payment amount and Approval status
  let devolucion = '';
  let isApproved = false;
  let estado = 'Rechazado';

  const paymentMatch = bodyText.match(/Procederemos a realizar el pago correspondiente a \$\s*([\d\.]+)/i);
  if (paymentMatch) {
    const amountStr = paymentMatch[1].replace(/\./g, '');
    const amountNum = parseInt(amountStr, 10);
    if (!Number.isNaN(amountNum) && amountNum > 0) {
      devolucion = amountNum;
      isApproved = true;
      estado = 'Liquidado';
    }
  }

  const formattedSolicitud = formatSolicitudForSheet(solicitud);

  return {
    solicitud,
    formattedSolicitud,
    fechaLiquidacion,
    estado,
    devolucion,
    isApproved
  };
}

/**
 * Heuristic prediction for medical expense items based on historical vocabulary
 * and optional recent emails.
 */
function predictItem(text = '', recentEmails = []) {
  if (!text && (!Array.isArray(recentEmails) || recentEmails.length === 0)) {
    return '';
  }

  const normalize = (str) =>
    (str || '')
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '');

  const normText = normalize(text);

  // 1. Direct match on given text
  for (const term of VOCABULARY) {
    const normTerm = normalize(term);
    const regex = new RegExp(`\\b${normTerm}\\b`, 'i');
    if (regex.test(normText)) {
      return term;
    }
  }

  // 2. Check recent emails if passed
  if (Array.isArray(recentEmails)) {
    for (const email of recentEmails) {
      const emailContent = normalize(
        `${email.subject || ''} ${email.snippet || ''} ${email.body || ''}`
      );
      for (const term of VOCABULARY) {
        const normTerm = normalize(term);
        const regex = new RegExp(`\\b${normTerm}\\b`, 'i');
        if (regex.test(emailContent)) {
          return term;
        }
      }
    }
  }

  return '';
}

/**
 * Converts an all-caps PDF prestación string to a readable title case.
 */
function toTitleCase(str) {
  return str
    .toLowerCase()
    .replace(/(^|\s)([a-záéíóúñ])/g, (match, prefix, letter) => prefix + letter.toUpperCase());
}

/**
 * Parses the text layer of an INSURANCE liquidation PDF (pdftotext -layout output).
 * Extracts the beneficiary (patient), the claimed value (SubTotal Valor Prest.)
 * and the item/prestación.
 */
function parseLiquidationPdf(text = '') {
  if (!text || typeof text !== 'string') {
    return { beneficiario: '', valorReclamado: '', item: '' };
  }

  const lines = text.split(/\r?\n/);

  // 1. Beneficiario: next non-empty line after the "Identificación Paciente" label
  //    (pdftotext renders the doubled n as "Indentificación").
  let beneficiario = '';
  const labelIdx = lines.findIndex((l) => /Indentificaci[oó]n Paciente/i.test(l));
  if (labelIdx >= 0) {
    for (let i = labelIdx + 1; i < lines.length; i++) {
      if (!lines[i].trim()) continue;
      beneficiario = lines[i].split(/\s{2,}/)[0].trim();
      break;
    }
  }

  // 2. Valor Reclamado: first currency amount on the SubTotal line.
  //    The "SubTotal ﴾$﴿" marker contains a lone $ without digits, so it is skipped.
  let valorReclamado = '';
  const subTotalLine = lines.find((l) => /SubTotal/i.test(l));
  if (subTotalLine) {
    const match = subTotalLine.match(/\$\s*([\d.]+)/);
    if (match) {
      const parsed = parseInt(match[1].replace(/\./g, ''), 10);
      if (!Number.isNaN(parsed)) valorReclamado = parsed;
    }
  }

  // 3. Item: first prestación row (starts with index 1) plus its continuation lines.
  let itemRaw = '';
  const rowIdx = lines.findIndex((l) => /^\s*1\s+[A-ZÁÉÍÓÚÑ]/.test(l));
  if (rowIdx >= 0) {
    const match = lines[rowIdx].match(/^\s*1\s+(.+?)\s{2,}/);
    if (match) itemRaw = match[1].trim();
    for (let i = rowIdx + 1; i < lines.length; i++) {
      const continuation = lines[i].trim();
      if (!continuation) break;
      if (!/^[A-ZÁÉÍÓÚÑ][A-ZÁÉÍÓÚÑ\s]*$/.test(continuation)) break;
      itemRaw += ` ${continuation}`;
    }
  }

  const normalizedItem = itemRaw.replace(/\s+/g, ' ').trim();
  const item = predictItem(normalizedItem) || (normalizedItem ? toTitleCase(normalizedItem) : '');

  return { beneficiario, valorReclamado, item };
}

module.exports = {
  VOCABULARY,
  extractHeader,
  extractBodyText,
  formatSolicitudForSheet,
  classifyMessage,
  parseDenuncio,
  parseLiquidacion,
  parseLiquidationPdf,
  predictItem
};
