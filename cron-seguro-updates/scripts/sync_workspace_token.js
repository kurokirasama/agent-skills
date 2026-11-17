#!/usr/bin/env node
/**
 * sync_workspace_token.js
 * CLI helper to sync Keytar Google Workspace OAuth credentials to the encrypted
 * token file required for headless execution (GEMINI_CLI_WORKSPACE_FORCE_FILE_STORAGE=true).
 */

const { ensureTokenFileSync } = require('./sheets_helper.js');

(async () => {
  const success = await ensureTokenFileSync();
  if (success) {
    console.log('[Token Sync] Google Workspace headless token is in sync.');
    process.exit(0);
  } else {
    console.error('[Token Sync] Failed to sync Google Workspace credentials from Keytar.');
    process.exit(1);
  }
})();
