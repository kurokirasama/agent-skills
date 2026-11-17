# BUG-02 fix: changed from `export def` to `def` because this file is loaded via `source`
# (not `use`), so `export` has no effect. Plain `def` makes the function available in the
# sourcing script's scope, which is the intended behavior.
def report_failure [
    skill_name: string,
    error_msg: string,
    stack_trace: string,
    impact: string,
    context: string = ""
] {
    let report = {
        type: "CRON_FAILURE_REPORT",
        skill: $skill_name,
        error: $error_msg,
        stack_trace: $stack_trace,
        impact: $impact,
        context: $context,
        timestamp: (date now | format date "%Y-%m-%d %H:%M:%S")
    }

    let message = $"**CRON FAILURE: ($skill_name)**\nError: ($error_msg)\nImpact: ($impact)"

    # Print the report as JSON with a marker for the agent to catch
    return $"AGENT_ACTION: report_failure ($report | to json -r)"
}