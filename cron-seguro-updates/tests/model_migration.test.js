const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { execSync } = require('node:child_process');
const path = require('node:path');
const os = require('node:os');

describe('OpenCode Model Availability & Responsiveness', () => {
  const opnBin = path.join(os.homedir(), '.opencode/bin/opencode');

  it('confirms opencode CLI binary exists', () => {
    const fs = require('node:fs');
    assert.ok(fs.existsSync(opnBin), 'opencode binary should exist at ~/.opencode/bin/opencode');
  });

  it('lists opencode/deepseek-v4.1-flash-free in active provider models', () => {
    const output = execSync(`${opnBin} models opencode`, { encoding: 'utf8' });
    const models = output.trim().split(/\r?\n/).map(m => m.trim());
    assert.ok(models.includes('opencode/deepseek-v4.1-flash-free'), 'deepseek-v4.1-flash-free should be listed');
    assert.ok(!models.includes('opencode/muse-spark-1.3-contributor-free'), 'muse-spark-1.3-contributor-free should NOT be in active list');
  });

  it('verifies deepseek-v4.1-flash-free responds to prompt via CLI', { timeout: 35000 }, () => {
    const output = execSync(`${opnBin} run --model opencode/deepseek-v4.1-flash-free "respond with ONLY the word pong"`, {
      encoding: 'utf8',
      timeout: 30000
    });
    assert.match(output, /pong/i, 'Response should contain pong');
  });
});
