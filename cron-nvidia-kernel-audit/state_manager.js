import fs from 'fs';
import path from 'path';

const STATE_FILE = 'skills/cron-nvidia-kernel-audit/state.json';
const STATE_DIR = path.dirname(STATE_FILE);

export const defaultState = {
    last_run: null,
    status: 'idle',
    recommendation: null,
    last_checked_kernel: null,
    findings: [],
    errors: []
};

export function readState() {
    if (!fs.existsSync(STATE_FILE)) {
        if (!fs.existsSync(STATE_DIR)) {
            fs.mkdirSync(STATE_DIR, { recursive: true });
        }
        writeState(defaultState);
        return defaultState;
    }
    const rawData = fs.readFileSync(STATE_FILE);
    return JSON.parse(rawData);
}

export function writeState(state) {
    if (!fs.existsSync(STATE_DIR)) {
        fs.mkdirSync(STATE_DIR, { recursive: true });
    }
    fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}
