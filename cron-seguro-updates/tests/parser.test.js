const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

// Import parser (will fail in RED phase until implemented)
const {
  classifyMessage,
  parseDenuncio,
  parseLiquidacion,
  predictItem,
  formatSolicitudForSheet,
  extractBodyText,
  VOCABULARY
} = require('../scripts/parser.js');

describe('Parser Engine', () => {
  describe('classifyMessage', () => {
    it('classifies "Claim Notice" as DENUNCIO based on Subject', () => {
      const msg = {
        payload: {
          headers: [{ name: 'Subject', value: 'Claim Notice 341034' }],
          body: { data: Buffer.from('Adjuntamos antecedentes generales').toString('base64') }
        }
      };
      assert.equal(classifyMessage(msg), 'DENUNCIO');
    });

    it('classifies denuncio as DENUNCIO based on body keyword when subject differs', () => {
      const msg = {
        payload: {
          headers: [{ name: 'Subject', value: 'Notificacion INSURANCE' }],
          body: { data: Buffer.from('se ha ingresado la denuncia N° 341034').toString('base64') }
        }
      };
      assert.equal(classifyMessage(msg), 'DENUNCIO');
    });

    it('classifies "Settlement Notice INSURANCE" as LIQUIDACION', () => {
      const msg = {
        payload: {
          headers: [{ name: 'Subject', value: 'Settlement Notice INSURANCE 1000 - 12345678 - 339814.pdf' }],
          body: { data: Buffer.from('Adjuntamos informe de liquidacion').toString('base64') }
        }
      };
      assert.equal(classifyMessage(msg), 'LIQUIDACION');
    });

    it('returns UNKNOWN for unrelated emails', () => {
      const msg = {
        payload: {
          headers: [{ name: 'Subject', value: 'Newsletter Semanal' }],
          body: { data: Buffer.from('Contenido de prueba').toString('base64') }
        }
      };
      assert.equal(classifyMessage(msg), 'UNKNOWN');
    });
  });

  describe('parseDenuncio', () => {
    it('extracts solicitud ID, date, and creates sheet row for denuncio', () => {
      const htmlBody = '<p>Estimado(a) <strong>USER NAME</strong> Junto con saludarle informamos a usted que con fecha 09-10-2026 se ha ingresado la denuncia N° 341034.</p>';
      const msg = {
        id: 'msg_denuncio_1',
        payload: {
          headers: [
            { name: 'Subject', value: 'Claim Notice 341034' },
            { name: 'Date', value: 'Fri, 9 Oct 2026 13:23:36 +0000' }
          ],
          body: { data: Buffer.from(htmlBody).toString('base64') }
        }
      };

      const result = parseDenuncio(msg);
      assert.equal(result.solicitud, '341034');
      assert.equal(result.formattedSolicitud, '341,034.00');
      assert.equal(result.denuncioDate, '09-10-2026');
      assert.equal(result.estado, 'Denunciado');
      assert.deepEqual(result.sheetRow, [
        '341,034.00',
        'USER NAME', // Beneficiario from the email body
        '', // Valor reclamado empty
        '', // Devolucion empty
        'Denunciado',
        '', // Item (predicted if passed)
        ''  // Fecha Liquidacion empty
      ]);
    });

    it('extracts beneficiario when name is followed by a <br> tag instead of a space', () => {
      const msg = {
        id: 'msg_br',
        payload: {
          headers: [{ name: 'Subject', value: 'Claim Notice 342981' }],
          body: {
            data: Buffer.from(
              'Estimado(a) USER NAME<br>Junto con saludarle informamos a usted que con fecha 21-10-2026 se ha ingresado la denuncia N° 342981.'
            ).toString('base64')
          }
        }
      };
      const result = parseDenuncio(msg);
      assert.equal(result.beneficiario, 'USER NAME');
    });

    it('populates predicted item in sheetRow if provided', () => {
      const msg = {
        id: 'msg_2',
        payload: {
          headers: [{ name: 'Subject', value: 'Claim Notice 341001' }],
          body: { data: Buffer.from('denuncia N° 341001 peg').toString('base64') }
        }
      };
      const result = parseDenuncio(msg, 'peg');
      assert.equal(result.sheetRow[5], 'peg');
    });

    it('extracts solicitud from body and date from Date header when subject has no ID and body has no date', () => {
      const msg = {
        id: 'msg_fallback',
        payload: {
          headers: [
            { name: 'Subject', value: 'Notificacion INSURANCE' },
            { name: 'Date', value: 'Wed, 14 Oct 2026 12:00:00 GMT' }
          ],
          body: { data: Buffer.from('Se ingreso la solicitud: 341999').toString('base64') }
        }
      };
      const result = parseDenuncio(msg);
      assert.equal(result.solicitud, '341999');
      assert.equal(result.denuncioDate, '14-10-2026');
    });
  });

  describe('parseLiquidacion', () => {
    it('parses approved liquidation with payment amount and date', () => {
      const htmlBody = `
        <dd>Adjuntamos informe de liquidacion correspondiente a los gastos medicos del contrato 5016 procesada con fecha 09-10-2026.</dd>
        <dd>Procederemos a realizar el pago correspondiente a $ 4392 a través de Transferencia/Vale Vista, en los próximos 2 días hábiles.</dd>
      `;
      const msg = {
        id: 'msg_liq_1',
        payload: {
          headers: [{ name: 'Subject', value: 'Settlement Notice INSURANCE 1000 - 12345678 - 339814.pdf' }],
          body: { data: Buffer.from(htmlBody).toString('base64') },
          parts: [
            { filename: '1000 - 12345678 - 339814.pdf', mimeType: 'application/octet-stream' }
          ]
        }
      };

      const result = parseLiquidacion(msg);
      assert.equal(result.solicitud, '339814');
      assert.equal(result.fechaLiquidacion, '09-10-2026');
      assert.equal(result.estado, 'Liquidado');
      assert.equal(result.devolucion, 4392);
      assert.equal(result.isApproved, true);
    });

    it('parses rejected liquidation without reimbursement payment', () => {
      const htmlBody = `
        <dd>Adjuntamos informe de liquidacion correspondiente a los gastos medicos del contrato 5016 procesada con fecha 05-09-2026.</dd>
        <dd>El siniestro no presenta reembolso según las condiciones del contrato.</dd>
      `;
      const msg = {
        id: 'msg_liq_rej',
        payload: {
          headers: [{ name: 'Subject', value: 'Settlement Notice INSURANCE 1000 - 12345678 - 334948.pdf' }],
          body: { data: Buffer.from(htmlBody).toString('base64') },
          parts: [
            { filename: '1000 - 12345678 - 334948.pdf', mimeType: 'application/octet-stream' }
          ]
        }
      };

      const result = parseLiquidacion(msg);
      assert.equal(result.solicitud, '334948');
      assert.equal(result.fechaLiquidacion, '05-09-2026');
      assert.equal(result.estado, 'Rechazado');
      assert.equal(result.devolucion, '');
      assert.equal(result.isApproved, false);
    });

    it('extracts solicitud from subject line when attachment parts are absent', () => {
      const msg = {
        id: 'msg_no_parts',
        payload: {
          headers: [{ name: 'Subject', value: 'Settlement Notice INSURANCE 1000 - 12345678 - 338577.pdf' }],
          body: { data: Buffer.from('procesada con fecha 01-10-2026').toString('base64') }
        }
      };
      const result = parseLiquidacion(msg);
      assert.equal(result.solicitud, '338577');
      assert.equal(result.fechaLiquidacion, '01-10-2026');
    });
  });

  describe('predictItem', () => {
    it('matches exact and multi-word terms from vocabulary', () => {
      assert.equal(predictItem('Consulta médica con specialist_a en clinica'), 'specialist_a');
      assert.equal(predictItem('Receta para eval plantillas ortopedicas'), 'eval plantillas');
      assert.equal(predictItem('Boleta plantillas biomecanicas'), 'plantillas');
      assert.equal(predictItem('Compra de peg gastro'), 'peg');
      assert.equal(predictItem('Tratamiento treatment_a de crecimiento'), 'treatment_a');
      assert.equal(predictItem('Sesion de therapy_a terapia'), 'therapy_a');
      assert.equal(predictItem('Farmacia preparacion compounded'), 'compounded');
      assert.equal(predictItem('Examen test cutaneo alergias'), 'test cutaneo');
      assert.equal(predictItem('Reacción de alergia estacional'), 'alergia');
      assert.equal(predictItem('Compra en farmacia medicamentos varios'), 'medicamentos');
      assert.equal(predictItem('Consulta con derma especialista'), 'derma');
    });

    it('matches vocabulary in recent emails if text has no keywords', () => {
      const recentEmails = [
        { subject: 'Boleta de atención', snippet: 'Compra de compounded en farmacia' }
      ];
      assert.equal(predictItem('', recentEmails), 'compounded');
    });

    it('returns empty string if no keywords match', () => {
      assert.equal(predictItem('Sin descripcion alguna'), '');
      assert.equal(predictItem(''), '');
      assert.equal(predictItem(null), '');
    });
  });

  describe('formatSolicitudForSheet', () => {
    it('formats plain digits as comma-separated thousands with .00 decimal', () => {
      assert.equal(formatSolicitudForSheet('341034'), '341,034.00');
      assert.equal(formatSolicitudForSheet(341034), '341,034.00');
      assert.equal(formatSolicitudForSheet('339814'), '339,814.00');
    });

    it('returns empty string for invalid or empty input', () => {
      assert.equal(formatSolicitudForSheet(''), '');
      assert.equal(formatSolicitudForSheet(null), '');
    });
  });

  describe('extractBodyText', () => {
    it('recursively extracts base64 text from payload and parts', () => {
      const payload = {
        body: { data: Buffer.from('Header text. ').toString('base64') },
        parts: [
          { body: { data: Buffer.from('Part 1 text. ').toString('base64') } },
          {
            parts: [
              { body: { data: Buffer.from('Nested part 2 text.').toString('base64') } }
            ]
          }
        ]
      };
      const text = extractBodyText(payload);
      assert.equal(text, 'Header text. Part 1 text. Nested part 2 text.');
    });
  });
});
