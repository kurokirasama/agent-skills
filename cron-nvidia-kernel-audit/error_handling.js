// error_handling.js
// Error handling and loop-breaking logic for cron-nvidia-kernel-audit

export function logError(state, error, stage) {
    const updatedState = { ...state };
    if (!updatedState.errors) updatedState.errors = [];
    
    updatedState.errors.push({
        timestamp: new Date().toISOString(),
        stage,
        message: error.message || String(error)
    });
    
    return updatedState;
}

export function shouldHalt(state, stage) {
    if (!state.errors) return false;
    
    // Halt if the same stage has failed 3 or more times recently
    const stageErrors = state.errors.filter(e => e.stage === stage);
    return stageErrors.length >= 3;
}

export function performAutoFix(state, stage) {
    // Placeholder for auto-fix logic
    // For now, it just returns the state as is
    console.log(`Attempting auto-fix for stage: ${stage}`);
    return state;
}
