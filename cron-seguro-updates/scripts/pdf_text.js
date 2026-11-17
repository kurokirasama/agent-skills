/**
 * pdf_text.js
 * Converts PDF bytes to text using the system pdftotext (poppler).
 * INSURANCE liquidation PDFs carry a text layer, so no OCR is required.
 */

const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

/**
 * Extracts the text layer of a PDF buffer using `pdftotext -layout`.
 * Returns the text; throws if pdftotext is unavailable or conversion fails.
 */
function extractPdfText(buffer) {
  const tmpPath = path.join(
    os.tmpdir(),
    `insurance_${process.pid}_${Date.now()}_${Math.random().toString(36).slice(2)}.pdf`
  );
  try {
    fs.writeFileSync(tmpPath, buffer);
    return execFileSync('pdftotext', ['-layout', tmpPath, '-'], {
      encoding: 'utf8',
      timeout: 20000
    });
  } finally {
    try {
      fs.unlinkSync(tmpPath);
    } catch {
      // Ignore temp cleanup failures
    }
  }
}

module.exports = { extractPdfText };
