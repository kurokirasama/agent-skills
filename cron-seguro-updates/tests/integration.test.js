const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

// Import synchronizer (will fail in RED phase until implemented)
const { syncSeguroUpdates } = require('../scripts/sync_seguro.js');

describe('End-to-End INSURANCE Synchronization Engine', () => {
  it('processes denuncios, handles duplicates, updates liquidations, and labels messages', async () => {
    const apiCalls = [];

    // Mock initial spreadsheet data
    const sheetData = [
      ['Nº Solicitud', 'Beneficiario', 'Valor Reclamado', 'Devolución', 'Estado', 'Item', 'Fecha Liquidacion'],
      ['341,034.00', 'BENEFICIARY ONE', '20000', '', 'Denunciado', 'eval plantillas', ''],
      ['334,948.00', 'BENEFICIARY TWO', '55000', '', 'Denunciado', 'specialist_b', '']
    ];

    // Mock Gmail messages
    const mockMessages = [
      { id: 'msg_new_denuncio', threadId: 'th_1' },
      { id: 'msg_dup_denuncio', threadId: 'th_1' },
      { id: 'msg_approved_liq', threadId: 'th_2' },
      { id: 'msg_rejected_liq', threadId: 'th_3' }
    ];

    const messageDetailsMap = {
      msg_new_denuncio: {
        id: 'msg_new_denuncio',
        payload: {
          headers: [{ name: 'Subject', value: 'Claim Notice 341050' }],
          body: { data: Buffer.from('se ha ingresado la denuncia N° 341050 con fecha 14-10-2026. plantillas').toString('base64') }
        }
      },
      msg_dup_denuncio: {
        id: 'msg_dup_denuncio',
        payload: {
          headers: [{ name: 'Subject', value: 'Claim Notice 341050' }],
          body: { data: Buffer.from('se ha ingresado la denuncia N° 341050 con fecha 14-10-2026. plantillas').toString('base64') }
        }
      },
      msg_approved_liq: {
        id: 'msg_approved_liq',
        payload: {
          headers: [{ name: 'Subject', value: 'Settlement Notice INSURANCE 1000 - 12345678 - 341034.pdf' }],
          body: { data: Buffer.from('procesada con fecha 12-10-2026. Procederemos a realizar el pago correspondiente a $ 15000').toString('base64') },
          parts: [{ filename: '1000 - 12345678 - 341034.pdf', mimeType: 'application/octet-stream' }]
        }
      },
      msg_rejected_liq: {
        id: 'msg_rejected_liq',
        payload: {
          headers: [{ name: 'Subject', value: 'Settlement Notice INSURANCE 1000 - 12345678 - 334948.pdf' }],
          body: { data: Buffer.from('procesada con fecha 11-10-2026. El siniestro no presenta reembolso').toString('base64') },
          parts: [{ filename: '1000 - 12345678 - 334948.pdf', mimeType: 'application/octet-stream' }]
        }
      }
    };

    const mockClient = {
      request: async (opts) => {
        apiCalls.push(opts);

        // Sheets metadata (grid id resolution)
        if (opts.url.includes('fields=sheets.properties')) {
          return { data: { sheets: [{ properties: { sheetId: 620908791, title: 'Insurance Tracker' } }] } };
        }

        // Gmail labels list
        if (opts.url.includes('/gmail/v1/users/me/labels') && opts.method === 'GET') {
          return { data: { labels: [{ id: 'Label_seguro_id', name: 'seguro/procesado' }] } };
        }

        // Gmail search
        if (opts.url.includes('/gmail/v1/users/me/messages?') && opts.method === 'GET') {
          return { data: { messages: mockMessages } };
        }

        // Gmail message details
        if (opts.url.match(/\/messages\/([^?]+)\?format=full/)) {
          const id = opts.url.match(/\/messages\/([^?]+)\?format=full/)[1];
          return { data: messageDetailsMap[id] };
        }

        // Gmail message modify
        if (opts.url.includes('/modify') && opts.method === 'POST') {
          return { data: { id: 'modified' } };
        }

        // Sheets fetch rows
        if (opts.url.includes('/values/Insurance') && opts.method === 'GET') {
          return { data: { values: sheetData } };
        }

        // Sheets batchUpdate (insertDimension or values update)
        if (opts.url.includes(':batchUpdate') || opts.url.includes('/values:batchUpdate')) {
          return { data: { updated: true } };
        }

        // Sheets values PUT
        if (opts.method === 'PUT') {
          return { data: { updatedRows: 1 } };
        }

        return { data: {} };
      }
    };

    const result = await syncSeguroUpdates({
      client: mockClient,
      spreadsheetId: 'test-sheet-id',
      dryRun: false
    });

    assert.equal(result.totalProcessed, 4);
    assert.equal(result.denunciosInserted, 1);
    assert.equal(result.duplicatesSkipped, 1);
    assert.equal(result.liquidacionesUpdated, 2);

    // Verify modify was called for all 4 messages
    const modifyCalls = apiCalls.filter(c => c.url.includes('/modify'));
    assert.equal(modifyCalls.length, 4);

    // Verify insertDimension was called exactly once for the new denuncio (not for duplicate)
    const insertDimCalls = apiCalls.filter(c => c.data?.requests?.[0]?.insertDimension);
    assert.equal(insertDimCalls.length, 1);
  });

  it('respects dryRun mode without making write API calls', async () => {
    const apiCalls = [];
    const mockClient = {
      request: async (opts) => {
        apiCalls.push(opts);
        if (opts.url.includes('/labels')) return { data: { labels: [{ id: 'Label_1', name: 'seguro/procesado' }] } };
        if (opts.url.includes('/messages?')) return { data: { messages: [{ id: 'msg_1' }] } };
        if (opts.url.includes('/messages/msg_1?')) {
          return {
            data: {
              id: 'msg_1',
              payload: {
                headers: [{ name: 'Subject', value: 'Claim Notice 341999' }],
                body: { data: Buffer.from('denuncia N° 341999').toString('base64') }
              }
            }
          };
        }
        if (opts.url.includes('/values/Insurance')) return { data: { values: [['Nº Solicitud']] } };
        return { data: {} };
      }
    };

    const result = await syncSeguroUpdates({
      client: mockClient,
      spreadsheetId: 'test-sheet-id',
      dryRun: true
    });

    assert.equal(result.dryRun, true);
    assert.equal(result.denunciosInserted, 1);

    // Ensure NO POST or PUT calls were made
    const writeCalls = apiCalls.filter(c => c.method === 'POST' || c.method === 'PUT');
    assert.equal(writeCalls.length, 0);
  });

  it('handles orphan liquidations and unknown messages appropriately', async () => {
    const mockMessages = [
      { id: 'msg_orphan_liq' },
      { id: 'msg_spam' }
    ];

    const messageMap = {
      msg_orphan_liq: {
        id: 'msg_orphan_liq',
        payload: {
          headers: [{ name: 'Subject', value: 'Settlement Notice INSURANCE 1000 - 12345678 - 338888.pdf' }],
          body: { data: Buffer.from('procesada con fecha 10-10-2026. Procederemos a realizar el pago correspondiente a $ 8000').toString('base64') },
          parts: [{ filename: '1000 - 12345678 - 338888.pdf', mimeType: 'application/octet-stream' }]
        }
      },
      msg_spam: {
        id: 'msg_spam',
        payload: {
          headers: [{ name: 'Subject', value: 'Promocion de Seguros' }],
          body: { data: Buffer.from('Publicidad').toString('base64') }
        }
      }
    };

    const mockClient = {
      request: async (opts) => {
        if (opts.url.includes('fields=sheets.properties')) {
          return { data: { sheets: [{ properties: { sheetId: 620908791, title: 'Insurance Tracker' } }] } };
        }
        if (opts.url.includes('/labels')) return { data: { labels: [{ id: 'Label_1', name: 'seguro/procesado' }] } };
        if (opts.url.includes('/messages?')) return { data: { messages: mockMessages } };
        if (opts.url.match(/\/messages\/([^?]+)\?format=full/)) {
          const id = opts.url.match(/\/messages\/([^?]+)\?format=full/)[1];
          return { data: messageMap[id] };
        }
        if (opts.url.includes('/values/Insurance')) return { data: { values: [['Nº Solicitud']] } };
        return { data: { updated: true } };
      }
    };

    const result = await syncSeguroUpdates({
      client: mockClient,
      spreadsheetId: 'test-sheet-id',
      dryRun: false
    });

    assert.equal(result.liquidacionesUpdated, 1);
    assert.equal(result.unknownSkipped, 1);
    assert.equal(result.totalProcessed, 2);
  });

  it('passes the labeled query when reconcileAll is set', async () => {
    const searchUrls = [];
    const mockClient = {
      request: async (opts) => {
        if (opts.url.includes('fields=sheets.properties')) {
          return { data: { sheets: [{ properties: { sheetId: 620908791, title: 'Insurance Tracker' } }] } };
        }
        if (opts.url.includes('/labels')) return { data: { labels: [{ id: 'Label_1', name: 'seguro/procesado' }] } };
        if (opts.url.includes('/messages?')) {
          searchUrls.push(opts.url);
          return { data: { messages: [] } };
        }
        if (opts.url.includes('/values/Insurance')) return { data: { values: [] } };
        return { data: {} };
      }
    };

    await syncSeguroUpdates({
      client: mockClient,
      spreadsheetId: 'test-sheet-id',
      dryRun: true,
      reconcileAll: true
    });

    assert.equal(searchUrls.length, 1);
    const decoded = decodeURIComponent(searchUrls[0]);
    assert.match(decoded, /q=\(from:support@insurance.example.com/);
    assert.doesNotMatch(decoded, /-label:insurance\/procesado/);
  });
});

