const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const { parseLiquidationPdf } = require('../scripts/parser.js');
const { downloadPdfAttachment } = require('../scripts/gmail_label_manager.js');
const { reconcileRowFields } = require('../scripts/sheets_helper.js');

const fixture = (name) =>
  fs.readFileSync(path.join(__dirname, 'fixtures', name), 'utf8');

describe('Liquidation PDF field parsing', () => {
  it('extracts beneficiary, claimed value and item from an approved liquidation PDF', () => {
    const result = parseLiquidationPdf(fixture('pdf_341034.txt'));

    assert.equal(result.beneficiario, 'BENEFICIARY ONE');
    assert.equal(result.valorReclamado, 20000);
    assert.equal(result.item, 'Atencion Kinesiologica Integral');
  });

  it('extracts fields from a rejected liquidation PDF and maps the item vocabulary', () => {
    const result = parseLiquidationPdf(fixture('pdf_341001.txt'));

    assert.equal(result.beneficiario, 'BENEFICIARY TWO');
    assert.equal(result.valorReclamado, 12116);
    assert.equal(result.item, 'medicamentos');
  });

  it('returns empty fields for unrecognized text', () => {
    const result = parseLiquidationPdf('nothing useful here');
    assert.equal(result.beneficiario, '');
    assert.equal(result.valorReclamado, '');
    assert.equal(result.item, '');
  });
});

describe('Gmail PDF attachment download', () => {
  it('finds the PDF part and decodes the attachment payload', async () => {
    const payload = Buffer.from('%PDF-1.4 test');
    const requestedUrls = [];
    const client = {
      request: async (opts) => {
        requestedUrls.push(opts.url);
        return { data: { data: payload.toString('base64url') } };
      }
    };
    const messagePayload = {
      parts: [
        { filename: 'image.png', mimeType: 'image/png', body: { attachmentId: 'img' } },
        {
          filename: '1000 - 12345678 - 341034.pdf',
          mimeType: 'application/octet-stream',
          body: { attachmentId: 'att-123' }
        }
      ]
    };

    const buf = await downloadPdfAttachment(client, 'msg-1', messagePayload);
    assert.ok(Buffer.isBuffer(buf));
    assert.equal(buf.toString(), '%PDF-1.4 test');
    assert.match(requestedUrls[0], /messages\/msg-1\/attachments\/att-123/);
  });

  it('returns null when the message has no PDF attachment', async () => {
    const client = { request: async () => assert.fail('should not call API') };
    assert.equal(await downloadPdfAttachment(client, 'msg-2', { parts: [] }), null);
  });
});

describe('reconcileRowFields', () => {
  it('overwrites differing authoritative values and reports every change', async () => {
    const calls = [];
    const client = {
      request: async (opts) => {
        calls.push(opts);
        return { data: {} };
      }
    };
    // Row layout: [A solicitud, B beneficiario, C valor, D devolucion, E estado, F item, G fecha]
    const rowValues = ['341,034.00', 'OLD NAME', '20000', '4392', 'Liquidado', 'item', '19-10-2026'];

    const res = await reconcileRowFields(client, 'sheet-1', 3, rowValues, {
      B: 'BENEFICIARY ONE',
      C: 99999,
      F: 'Atencion Kinesiologica Integral'
    });

    assert.equal(res.updated, true);
    assert.equal(calls.length, 1);
    const columns = res.changes.map((c) => c.column).sort();
    assert.deepEqual(columns, ['B', 'C']); // F is non-empty -> fill-only, not overwritten
    assert.equal(res.changes.find((c) => c.column === 'B').from, 'OLD NAME');
    assert.equal(res.changes.find((c) => c.column === 'C').to, 99999);
  });

  it('treats the same name in another order and the same amount as equal', async () => {
    const client = { request: async () => assert.fail('should not call API') };
    const rowValues = ['341,034.00', 'BENEFICIARY ONE', '20.000', '4392', 'Liquidado', 'item', '19-10-2026'];
    const res = await reconcileRowFields(client, 'sheet-1', 3, rowValues, {
      B: 'BENEFICIARY ONE',
      C: 20000,
      F: 'item'
    });
    assert.equal(res.updated, false);
  });

  it('never writes empty incoming values', async () => {
    const client = { request: async () => assert.fail('should not call API') };
    const rowValues = ['341,034.00', 'NAME', '20000', '4392', 'Liquidado', 'item', '19-10-2026'];
    const res = await reconcileRowFields(client, 'sheet-1', 3, rowValues, {
      B: '',
      C: null,
      F: undefined
    });
    assert.equal(res.updated, false);
  });
});
