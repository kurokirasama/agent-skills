// research_discovery.js
// Logic for performing web research on Ubuntu kernel/NVIDIA compatibility

export async function generateQueries(kernelVersion) {
    return [
        `Ubuntu 24.04 "${kernelVersion}" NVIDIA black screen hard freeze`,
        `site:discourse.ubuntu.com Ubuntu 24.04 "${kernelVersion}" NVIDIA`,
        `site:forums.developer.nvidia.com Ubuntu 24.04 "${kernelVersion}"`,
        `site:github.com/hyprwm/Hyprland/issues "${kernelVersion}" kernel`
    ];
}

// Note: In actual skill execution, this would call mcp_standard-exa_web_search_exa
export async function performResearch(kernelVersion, searchTool) {
    const queries = await generateQueries(kernelVersion);
    const allResults = [];

    for (const query of queries) {
        // Simulation of tool call
        // const results = await searchTool({ query, numResults: 5 });
        // allResults.push(...results);
    }

    return allResults;
}

export function analyzeFindings(findings) {
    let recommendation = 'GO';
    let reason = 'No recent critical issues found.';
    let actionSteps = [];

    const criticalIssues = findings.filter(f => 
        f.summary.toLowerCase().includes('freeze') || 
        f.summary.toLowerCase().includes('black screen')
    );

    if (criticalIssues.length > 0) {
        // Check if any of these critical issues have a resolution
        const resolvedIssues = criticalIssues.filter(f => 
            f.summary.toLowerCase().includes('fixed') || 
            f.summary.toLowerCase().includes('resolved') ||
            f.summary.toLowerCase().includes('patch')
        );

        if (resolvedIssues.length === criticalIssues.length) {
            recommendation = 'GO';
            reason = 'Critical issues found but appear to be resolved in newer versions/patches.';
            actionSteps.push('Ensure NVIDIA driver version is updated to the latest available.');
        } else {
            recommendation = 'NO_GO';
            reason = 'Recent reports of freezes or black screens found without confirmed resolution.';
        }
    }

    // Check for common workarounds
    if (findings.some(f => f.summary.includes('nvidia-drm.modeset=1'))) {
        actionSteps.push('Add "nvidia-drm.modeset=1" to kernel parameters if not already present.');
    }

    return { recommendation, reason, actionSteps };
}
