// reporting.js
// Logic for generating the Markdown report and JSON output for cron-nvidia-kernel-audit

export function generateMarkdownReport(auditResult) {
    const { recommendation, reason, actionSteps, last_run } = auditResult;
    const dateStr = last_run ? new Date(last_run).toLocaleDateString() : new Date().toLocaleDateString();
    
    let report = `# NVIDIA Kernel Audit Summary - ${dateStr}\n\n`;
    report += `**Recommendation**: ${recommendation}\n`;
    report += `**Reason**: ${reason}\n\n`;

    if (actionSteps && actionSteps.length > 0) {
        report += `### Actionable Steps\n`;
        actionSteps.forEach(step => {
            report += `- ${step}\n`;
        });
    }

    return report;
}

export function wrapReport(markdownReport) {
    return {
        report: markdownReport
    };
}
