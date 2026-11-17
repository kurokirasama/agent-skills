const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

describe('Mutation Testing Suite for Full Presupuesto Sync Pipeline', () => {
  const tempDir = path.resolve(__dirname, '../.tmp_mutants');

  const mutations = [
    // Phase 1: drive_helper.js mutations
    {
      file: 'drive_helper.js',
      testFile: 'drive_discovery.test.js',
      description: 'Mutate parseTransactionAmount: return 1 instead of 0 for falsy input',
      from: 'if (!val) return 0;',
      to: 'if (!val) return 1;'
    },
    {
      file: 'drive_helper.js',
      testFile: 'drive_discovery.test.js',
      description: 'Mutate parseTransactionAmount: fail to strip dots from Chilean pesos',
      from: "const digitsOnly = str.replace(/[.,\\s]/g, '');",
      to: "const digitsOnly = str.replace(/[,\\s]/g, '');"
    },
    {
      file: 'drive_helper.js',
      testFile: 'drive_discovery.test.js',
      description: 'Mutate parseMachTransactions: start loop at index 0 (including headers)',
      from: 'for (let i = 1; i < rows.length; i++) {',
      to: 'for (let i = 0; i < rows.length; i++) {'
    },
    {
      file: 'drive_helper.js',
      testFile: 'drive_discovery.test.js',
      description: 'Mutate findCurrentMonthMachFile: corrupt file prefix pattern',
      from: 'const targetName = `BANK_${year}.${month}`;',
      to: 'const targetName = `NOT_BANK_${year}.${month}`;'
    },
    {
      file: 'drive_helper.js',
      testFile: 'drive_discovery.test.js',
      description: 'Mutate findCurrentMonthMachFile: drop fallback to latest file',
      from: 'return exact || files[0];',
      to: 'return exact || null;'
    },

    // Phase 1: autopay_parser.js mutations
    {
      file: 'autopay_parser.js',
      testFile: 'autopay_parser.test.js',
      description: 'Mutate parsePacSection: wrong AUTOPAY header keyword check',
      from: "if (colE.toUpperCase() === 'AUTOPAY') {",
      to: "if (colE.toUpperCase() === 'NOT_AUTOPAY') {"
    },
    {
      file: 'autopay_parser.js',
      testFile: 'autopay_parser.test.js',
      description: 'Mutate parsePacSection: invert pagado boolean check',
      from: "String(rawPagado || '').trim().toUpperCase() === 'TRUE';",
      to: "String(rawPagado || '').trim().toUpperCase() !== 'TRUE';"
    },
    {
      file: 'autopay_parser.js',
      testFile: 'autopay_parser.test.js',
      description: 'Mutate parsePacSection: 0-indexed row index instead of 1-indexed',
      from: 'rowIndex: i + 1,',
      to: 'rowIndex: i,'
    },
    {
      file: 'autopay_parser.js',
      testFile: 'autopay_parser.test.js',
      description: 'Mutate parsePacSection: ignore section delimiter and do not break',
      from: 'if (colE && colE.toUpperCase() !== \'AUTOPAY\') {',
      to: 'if (false) {'
    },
    {
      file: 'autopay_parser.js',
      testFile: 'autopay_parser.test.js',
      description: 'Mutate parsePacSection: drop concept extraction',
      from: "const concepto = String(row[0] !== undefined && row[0] !== null ? row[0] : '').trim();",
      to: "const concepto = '';"
    },

    // Phase 2: matcher.js mutations
    {
      file: 'matcher.js',
      testFile: 'matcher.test.js',
      description: 'Mutate isAmountWithinTolerance: reduce tolerance to 1% (breaking currency variance)',
      from: 'return relDiff <= 0.15 || absDiff <= 2000;',
      to: 'return relDiff <= 0.01 && absDiff <= 50;'
    },
    {
      file: 'matcher.js',
      testFile: 'matcher.test.js',
      description: 'Mutate matchPacTransactions: invert pacItem.pagado check',
      from: 'if (pacItem.pagado) {',
      to: 'if (!pacItem.pagado) {'
    },
    {
      file: 'matcher.js',
      testFile: 'matcher.test.js',
      description: 'Mutate matchPacTransactions: drop NEWLY_PAID status condition',
      from: "} else if (matchedTransaction) {\n      status = 'NEWLY_PAID';",
      to: "} else if (false) {\n      status = 'NEWLY_PAID';"
    },
    {
      file: 'matcher.js',
      testFile: 'matcher.test.js',
      description: 'Mutate generateCheckboxUpdates: target Column A instead of Column G',
      from: "range: `'${tabName}'!G${m.pacItem.rowIndex}`,",
      to: "range: `'${tabName}'!A${m.pacItem.rowIndex}`,"
    },
    {
      file: 'matcher.js',
      testFile: 'matcher.test.js',
      description: 'Mutate markPacRowPaid: set checkbox to false instead of true',
      from: 'values: [[true]]',
      to: 'values: [[false]]'
    },
    {
      file: 'matcher.js',
      testFile: 'matcher.test.js',
      description: 'Mutate updatePacCheckboxes: change method from POST to GET',
      from: "method: 'POST',",
      to: "method: 'GET',"
    },

    // Phase 3: sync_presupuesto.js mutations
    {
      file: 'sync_presupuesto.js',
      testFile: 'integration.test.js',
      description: 'Mutate syncBudgetAutoPay: disable Sheets update even when not dryRun',
      from: 'if (!dryRun && updates.length > 0) {',
      to: 'if (false && updates.length > 0) {'
    },
    {
      file: 'sync_presupuesto.js',
      testFile: 'integration.test.js',
      description: 'Mutate syncBudgetAutoPay: wrong status on missing file',
      from: "status: 'NO_FILE',",
      to: "status: 'FOUND_FILE',"
    },
    {
      file: 'sync_presupuesto.js',
      testFile: 'integration.test.js',
      description: 'Mutate formatMarkdownReport: drop Newly Marked as Paid header',
      from: "lines.push('### Newly Marked as Paid');",
      to: "lines.push('### Wrong Section Header');"
    }
  ];

  it('kills all injected mutants (Mutation Score >= 70%)', () => {
    let killed = 0;
    const total = mutations.length;
    const skillDir = path.resolve(__dirname, '..');

    fs.rmSync(tempDir, { recursive: true, force: true });
    fs.mkdirSync(tempDir, { recursive: true });

    try {
      for (let index = 0; index < mutations.length; index++) {
        const m = mutations[index];
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

        const testPath = path.join(workDir, 'tests', m.testFile);

        let failed = false;
        try {
          const cleanEnv = { ...process.env };
          delete cleanEnv.NODE_TEST_CONTEXT;
          execFileSync('node', ['--test', testPath], {
            env: cleanEnv,
            stdio: 'pipe',
            timeout: 10000
          });
        } catch {
          failed = true;
        }

        if (failed) {
          killed++;
        }
        console.log(`[Mutant] ${m.description} -> ${failed ? 'KILLED' : 'SURVIVED'}`);
      }
    } finally {
      fs.rmSync(tempDir, { recursive: true, force: true });
    }

    const score = (killed / total) * 100;
    console.log(`\nMutation Testing Results: ${killed}/${total} killed (${score.toFixed(1)}%)`);
    assert.ok(score >= 70, `Expected mutation score >= 70%, got ${score}%`);
  });
});
