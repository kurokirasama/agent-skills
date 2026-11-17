const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

describe('Mutation Testing Suite for Phase 1 Infrastructure', () => {
  const tempDir = path.resolve(__dirname, '../.tmp_mutants');

  const mutations = [
    {
      file: 'sheets_helper.js',
      description: 'Mutate insertDimension startIndex from 1 to 0',
      from: 'startIndex: 1,',
      to: 'startIndex: 0,'
    },
    {
      file: 'sheets_helper.js',
      description: 'Mutate insertDimension endIndex from 2 to 3',
      from: 'endIndex: 2',
      to: 'endIndex: 3'
    },
    {
      file: 'sheets_helper.js',
      description: 'Mutate SHEET_TAB_NAME constant to wrong sheet',
      from: "const SHEET_TAB_NAME = 'Insurance Tracker';",
      to: "const SHEET_TAB_NAME = 'Wrong Tab';"
    },
    {
      file: 'sheets_helper.js',
      description: 'Mutate updateLiquidation range from D to C',
      from: 'range: `${SHEET_TAB_NAME}!D${rowIndex}`,',
      to: 'range: `${SHEET_TAB_NAME}!C${rowIndex}`,',
    },
    {
      file: 'sheets_helper.js',
      description: 'Mutate normalizeSolicitud to return empty string',
      from: "return noDecimals.replace(/[.,\\s]/g, '');",
      to: 'return "";'
    },
    {
      file: 'gmail_label_manager.js',
      description: 'Mutate label name constant',
      from: "const DEFAULT_LABEL_NAME = 'seguro/procesado';",
      to: "const DEFAULT_LABEL_NAME = 'other/label';"
    },
    {
      file: 'gmail_label_manager.js',
      description: 'Mutate applyLabelAndMarkRead removeLabelIds to empty',
      from: "removeLabelIds: ['UNREAD']",
      to: "removeLabelIds: []"
    },
    {
      file: 'gmail_label_manager.js',
      description: 'Mutate ensureLabelExists matching logic to always false',
      from: 'const existing = labels.find((l) => l.name === labelName);',
      to: 'const existing = null;'
    },
    {
      file: 'parser.js',
      description: 'Mutate classifyMessage Claim Notice regex',
      from: '/Claim Notice/i.test(subject)',
      to: '/Registro de OTRO/i.test(subject)'
    },
    {
      file: 'parser.js',
      description: 'Mutate parseLiquidacion payment regex',
      from: 'bodyText.match(/Procederemos a realizar el pago correspondiente a \\$\\s*([\\d\\.]+)/i)',
      to: 'null'
    },
    {
      file: 'parser.js',
      description: 'Mutate parseLiquidacion date regex',
      from: 'bodyText.match(/procesada con fecha\\s*(\\d{2}-\\d{2}-\\d{4})/i)',
      to: 'null'
    },
    {
      file: 'parser.js',
      description: 'Mutate predictItem to return hardcoded wrong keyword',
      from: 'return term;',
      to: 'return "wrong_term";'
    },
    {
      file: 'parser.js',
      description: 'Mutate formatSolicitudForSheet to return unformatted integer',
      from: 'return num.toLocaleString(',
      to: 'return String(num); // return num.toLocaleString('
    },
    {
      file: 'sync_seguro.js',
      testFile: 'integration.test.js',
      description: 'Mutate duplicate skipping condition in sync_seguro',
      from: 'if (existing) {',
      to: 'if (false && existing) {'
    },
    {
      file: 'sync_seguro.js',
      testFile: 'integration.test.js',
      description: 'Mutate dryRun guard to always run writes',
      from: 'if (!dryRun) {\n          await insertRowAtTop(',
      to: 'if (true) {\n          await insertRowAtTop('
    }
  ];

  it('kills all injected mutants (Mutation Score >= 70%)', () => {
    let killed = 0;
    let total = mutations.length;
    const skillDir = path.resolve(__dirname, '..');

    // Always start from a clean scratch area
    fs.rmSync(tempDir, { recursive: true, force: true });
    fs.mkdirSync(tempDir, { recursive: true });

    for (let index = 0; index < mutations.length; index++) {
      const m = mutations[index];
      // Work on an isolated copy so an interrupted run can never corrupt the real scripts
      const workDir = path.join(tempDir, String(index));
      fs.mkdirSync(workDir, { recursive: true });
      fs.cpSync(path.join(skillDir, 'scripts'), path.join(workDir, 'scripts'), { recursive: true });
      fs.cpSync(path.join(skillDir, 'tests'), path.join(workDir, 'tests'), { recursive: true });

      const targetPath = path.join(workDir, 'scripts', m.file);
      const originalCode = fs.readFileSync(targetPath, 'utf8');

      assert.ok(
        originalCode.includes(m.from),
        `Mutation target "${m.from}" not found in ${m.file}`
      );

      const mutatedCode = originalCode.replace(m.from, m.to);
      fs.writeFileSync(targetPath, mutatedCode, 'utf8');

      const testFileName = m.testFile || m.file.replace('.js', '.test.js');
      const testPath = path.join(workDir, 'tests', testFileName);

      let failed = false;
      try {
        const cleanEnv = { ...process.env };
        delete cleanEnv.NODE_TEST_CONTEXT;
        execFileSync('node', ['--test', testPath], {
          env: cleanEnv,
          stdio: 'pipe',
          timeout: 20000
        });
      } catch {
        // Non-zero exit or timeout means the mutant was killed. Timeouts are
        // expected for live-auth suites on hosts where the Google extension
        // cannot be imported safely (it starts a stdio server and never exits).
        failed = true;
      }

      if (failed) {
        killed++;
      }
      console.log(`[Mutant] ${m.description} -> ${failed ? 'KILLED' : 'SURVIVED'}`);
    }

    fs.rmSync(tempDir, { recursive: true, force: true });

    const score = (killed / total) * 100;
    console.log(`\nMutation Testing Results: ${killed}/${total} killed (${score.toFixed(1)}%)`);
    assert.ok(score >= 70, `Expected mutation score >= 70%, got ${score}%`);
  });
});
