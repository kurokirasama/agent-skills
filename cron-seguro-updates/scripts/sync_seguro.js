#!/usr/bin/env node
/**
 * sync_seguro.js
 * Orchestrator script for Seguro claims synchronization.
 * Ingests emails from INSURANCE, classifies denuncios vs liquidations,
 * manages duplicates, updates Insurance Tracker sheet, and marks emails as processed.
 */

const {
  DEFAULT_SPREADSHEET_ID,
  getGoogleClient,
  fetchSpreadsheetRows,
  findRowBySolicitud,
  insertRowAtTop,
  updateLiquidation,
  reconcileRowFields
} = require('./sheets_helper.js');

const {
  DEFAULT_LABEL_NAME,
  ALL_INSURANCE_QUERY,
  ensureLabelExists,
  applyLabelAndMarkRead,
  searchUnprocessedMessages,
  getMessageDetails,
  downloadPdfAttachment
} = require('./gmail_label_manager.js');

const {
  classifyMessage,
  parseDenuncio,
  parseLiquidacion,
  parseLiquidationPdf,
  predictItem,
  extractBodyText
} = require('./parser.js');

const { extractPdfText } = require('./pdf_text.js');

/**
 * Main synchronization engine.
 */
async function syncSeguroUpdates({
  client = null,
  spreadsheetId = DEFAULT_SPREADSHEET_ID,
  dryRun = false,
  reconcileAll = false,
  logger = console.log
} = {}) {
  if (!client) {
    client = await getGoogleClient();
  }

  logger(`[INSURANCE Sync] Starting sync (dryRun: ${dryRun}, reconcileAll: ${reconcileAll})...`);

  // 1. Ensure Gmail label exists
  let labelId = null;
  if (!dryRun) {
    labelId = await ensureLabelExists(client, DEFAULT_LABEL_NAME);
    logger(`[INSURANCE Sync] Using label "${DEFAULT_LABEL_NAME}" (ID: ${labelId})`);
  }

  // 2. Fetch current spreadsheet state
  logger(`[INSURANCE Sync] Fetching existing rows from spreadsheet ${spreadsheetId}...`);
  const rawRows = await fetchSpreadsheetRows(client, spreadsheetId);
  // Clone rows array for local state tracking during batch processing
  const rows = rawRows.map((r) => [...r]);
  logger(`[INSURANCE Sync] Loaded ${rows.length} existing rows from sheet.`);

  // 3. Search messages in Gmail (all processed emails when reconciling history)
  logger('[INSURANCE Sync] Searching INSURANCE messages in Gmail...');
  const searchQuery = reconcileAll ? ALL_INSURANCE_QUERY : undefined;
  const messages = await searchUnprocessedMessages(client, searchQuery);
  logger(`[INSURANCE Sync] Discovered ${messages.length} messages to process.`);

  let denunciosInserted = 0;
  let duplicatesSkipped = 0;
  let liquidacionesUpdated = 0;
  let unknownSkipped = 0;

  const processedDetails = [];

  for (let i = 0; i < messages.length; i++) {
    const msgRef = messages[i];
    const details = await getMessageDetails(client, msgRef.id);
    const msgType = classifyMessage(details);

    logger(`\n[INSURANCE Sync] (${i + 1}/${messages.length}) Message ${msgRef.id} -> Type: ${msgType}`);

    if (msgType === 'DENUNCIO') {
      const parsed = parseDenuncio(details);
      logger(`  Solicitud: ${parsed.solicitud} | Date: ${parsed.denuncioDate}`);

      // Check if claim already exists in sheet
      const existing = findRowBySolicitud(rows, parsed.solicitud);
      if (existing) {
        logger(`  [DUPLICATE] Solicitud ${parsed.solicitud} already present at Row ${existing.rowIndex}. Skipping insert.`);
        duplicatesSkipped++;
        if (!dryRun) {
          await applyLabelAndMarkRead(client, msgRef.id, labelId);
        }
        processedDetails.push({
          id: msgRef.id,
          type: 'DENUNCIO',
          solicitud: parsed.solicitud,
          action: 'DUPLICATE_SKIPPED'
        });
      } else {
        // Predict item using message snippet and body
        const fullText = `${details.snippet || ''} ${extractBodyText(details.payload)}`;
        const item = predictItem(fullText);
        parsed.sheetRow[5] = item;

        logger(`  [NEW CLAIM] Inserting row at Row 2 (Item: "${item || 'N/A'}")`);
        if (!dryRun) {
          await insertRowAtTop(client, spreadsheetId, null, parsed.sheetRow);
          await applyLabelAndMarkRead(client, msgRef.id, labelId);
        }

        // Insert at index 1 of local copy (directly after header row)
        rows.splice(1, 0, parsed.sheetRow);
        denunciosInserted++;
        processedDetails.push({
          id: msgRef.id,
          type: 'DENUNCIO',
          solicitud: parsed.solicitud,
          item,
          action: 'ROW_INSERTED'
        });
      }
    } else if (msgType === 'LIQUIDACION') {
      const parsed = parseLiquidacion(details);
      logger(`  Solicitud: ${parsed.solicitud} | Estado: ${parsed.estado} | Devolucion: $${parsed.devolucion || 0} | Fecha: ${parsed.fechaLiquidacion}`);

      // Enrich from the attached liquidation PDF (best-effort; never abort the sync)
      let pdfFields = null;
      try {
        const pdfBuffer = await downloadPdfAttachment(client, msgRef.id, details.payload);
        if (pdfBuffer) {
          const pdfText = extractPdfText(pdfBuffer);
          pdfFields = parseLiquidationPdf(pdfText);
          logger(`  [PDF] Beneficiario: ${pdfFields.beneficiario || 'N/A'} | Valor Reclamado: ${pdfFields.valorReclamado || 'N/A'} | Item: ${pdfFields.item || 'N/A'}`);
        }
      } catch (err) {
        logger(`  [WARN] Could not extract liquidation PDF fields: ${err.message}`);
      }

      const match = findRowBySolicitud(rows, parsed.solicitud);
      if (match) {
        logger(`  [UPDATE LIQUIDATION] Updating Row ${match.rowIndex} -> Estado: ${parsed.estado}`);
        if (!dryRun) {
          await updateLiquidation(
            client,
            spreadsheetId,
            match.rowIndex,
            parsed.estado,
            parsed.devolucion,
            parsed.fechaLiquidacion
          );
          if (pdfFields) {
            const reconciled = await reconcileRowFields(client, spreadsheetId, match.rowIndex, rows[match.rowIndex - 1], {
              B: pdfFields.beneficiario,
              C: pdfFields.valorReclamado,
              F: pdfFields.item
            });
            for (const change of reconciled.changes) {
              logger(`  [RECONCILE] ${parsed.solicitud} ${change.column}: "${change.from}" -> "${change.to}"`);
            }
          }
          await applyLabelAndMarkRead(client, msgRef.id, labelId);
        }

        // Update local copy (B/C reconciled, F fill-only)
        const rowToUpdate = rows[match.rowIndex - 1];
        if (rowToUpdate) {
          if (pdfFields) {
            if (pdfFields.beneficiario) rowToUpdate[1] = pdfFields.beneficiario;
            if (pdfFields.valorReclamado) rowToUpdate[2] = pdfFields.valorReclamado;
            if (!rowToUpdate[5] && pdfFields.item) rowToUpdate[5] = pdfFields.item;
          }
          rowToUpdate[3] = parsed.devolucion;
          rowToUpdate[4] = parsed.estado;
          rowToUpdate[6] = parsed.fechaLiquidacion;
        }

        liquidacionesUpdated++;
        processedDetails.push({
          id: msgRef.id,
          type: 'LIQUIDACION',
          solicitud: parsed.solicitud,
          rowIndex: match.rowIndex,
          estado: parsed.estado,
          devolucion: parsed.devolucion,
          action: 'ROW_UPDATED'
        });
      } else {
        logger(`  [ORPHAN LIQUIDATION] No matching denuncio found for solicitud ${parsed.solicitud}. Inserting new row at top.`);
        const orphanRow = [
          parsed.formattedSolicitud,
          pdfFields ? pdfFields.beneficiario || '' : '',
          pdfFields ? pdfFields.valorReclamado || '' : '',
          parsed.devolucion,
          parsed.estado,
          pdfFields ? pdfFields.item || '' : '',
          parsed.fechaLiquidacion
        ];

        if (!dryRun) {
          await insertRowAtTop(client, spreadsheetId, null, orphanRow);
          await applyLabelAndMarkRead(client, msgRef.id, labelId);
        }

        rows.splice(1, 0, orphanRow);
        liquidacionesUpdated++;
        processedDetails.push({
          id: msgRef.id,
          type: 'LIQUIDACION',
          solicitud: parsed.solicitud,
          action: 'ORPHAN_INSERTED'
        });
      }
    } else {
      logger('  [UNKNOWN] Unrecognized format. Skipping message.');
      unknownSkipped++;
      processedDetails.push({
        id: msgRef.id,
        type: 'UNKNOWN',
        action: 'SKIPPED'
      });
    }
  }

  const summary = {
    totalProcessed: messages.length,
    denunciosInserted,
    duplicatesSkipped,
    liquidacionesUpdated,
    unknownSkipped,
    dryRun,
    details: processedDetails
  };

  logger('\n========================================');
  logger('           INSURANCE SYNC REPORT             ');
  logger('========================================');
  logger(`- Total Messages Evaluated: ${summary.totalProcessed}`);
  logger(`- New Denuncios Prepended:  ${summary.denunciosInserted}`);
  logger(`- Duplicate Claims Skipped: ${summary.duplicatesSkipped}`);
  logger(`- Liquidaciones Updated:    ${summary.liquidacionesUpdated}`);
  logger(`- Unrecognized Skipped:     ${summary.unknownSkipped}`);
  logger(`- Dry Run Mode:             ${summary.dryRun}`);
  logger('========================================\n');

  return summary;
}

// CLI entry point
if (require.main === module) {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run') || args.includes('-d');
  const reconcileAll = args.includes('--reconcile-all');

  syncSeguroUpdates({ dryRun, reconcileAll })
    .then((summary) => {
      process.exit(0);
    })
    .catch((err) => {
      console.error('[INSURANCE Sync Error]', err);
      process.exit(1);
    });
}

module.exports = {
  syncSeguroUpdates
};
