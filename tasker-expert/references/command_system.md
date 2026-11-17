18. **Tasker Command System (General):**
    *   **Purpose:** A flexible system for triggering Profiles based on custom commands sent from various Tasker actions or contexts. Primarily useful for creating dynamic actions or simplifying setups where one Profile can handle multiple variations of a request based on command parameters.
    *   **Mechanism:**
        *   **Sending:** Commands are sent using actions like `Command` (code 385) or within parameters of other actions like `Set up Quick Setting Tile` (code 162, arg9/10/11) or `Widget v2` (code 461, arg13 JSON `command` property - *use only as fallback*).
        *   **Receiving:** A Profile is created using the `Command` **Event** context (code 2091).
    *   **Command Syntax:** Commands typically use the format `prefix=:=value1=:=value2=:=...`
        *   `prefix`: A unique identifier for the command type (e.g., `launchapp`, `setvolume`).
        *   `=:=`: The standard separator between the prefix and subsequent values/parameters.
        *   `value1`, `value2`, ...: The data being passed with the command.
    *   **Receiving Profile (`Command` Event - code 2091):**
        *   `Command` parameter (arg1): Filters which commands trigger the profile. Uses **Pattern Matching**. **Crucially, you CANNOT use variables in this filter field itself.** Examples: `launchapp=:=*` (catches all launchapp commands), `setvolume=:=media=:=*` (catches setvolume commands where the second part is exactly 'media'), `*lighton*` (catches any command containing 'lighton').
        *   `Variables` parameter (arg2): A comma-separated list of the **full local variable names** (e.g., `%app` or `%voltype,%level`) that Tasker should create in the triggered Task. Tasker takes the values extracted *after* each `=:=` separator (from the command that matched the filter in arg1) and assigns them sequentially to these specified local variables. The first value goes into the first variable, the second into the second, and so on.
        *   `Last Variable Is Array` parameter (arg3): If checked (value `1`), the *last* variable name listed in arg2 becomes a **Tasker Array** containing all remaining parts of the command separated by `=:=`. (e.g., Command: `mycmd=:=header=:=part1=:=part2`, Variables: `%header,%parts`, Last Array: True => `%header`="header", `%parts()`="part1,part2").
        *   **Implicit Output:** The full command string is available in the triggered Task as `%evtprm1`.
    *   **Advantages Over Direct Task Execution (`Perform Task`):**
        *   **Decoupling:** The sender doesn't need to know *which specific Task* will handle the command, only the command format. The receiving Profile routes the command, allowing the handling Task to be changed later without modifying senders.
        *   **Flexibility:** One receiving Profile can handle many command variations using parameters passed in the command string, reducing the need for multiple Profiles or Tasks (e.g., one `launchapp=:=*` profile vs. many profiles each launching a specific app).
        *   **Centralized Logic:** Consolidates the handling of related actions triggered from different places into a single Profile/Task.
    *   **Comparison with `Perform Task`:** While powerful for decoupling, the Command System adds an layer (the Profile). For direct, clear Task-to-Task calls within a known structure (like a Project), `Perform Task` is often simpler and offers clearer parameter passing (`%par1`, `%par2`, Return Value, Passthrough).
    *   **Use Cases (Beyond Widgets):** Triggering parameterized actions from Quick Settings, dynamically controlling profiles/tasks, decoupling task actions from specific triggers.
    *   **Widget Interaction:** Remember the strict rule: **PREFER Task Calling with Variables** for `Widget v2` interactions. Use the Command System *only* as a fallback, and if used, it **requires a Project structure** to hold the widget task and the reacting Command Profile/Task.
    *   **AutoApps Context:** The `=:=` syntax originates from AutoApps, but you should **NEVER** use or reference AutoApps components. Use the native Tasker `Command` event/action.
