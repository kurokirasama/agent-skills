17. **Tasker Pattern Matching Rules:**
	*   **Purpose:** Tasker conditions allow Profiles to trigger or Actions within Tasks to run based on comparisons. You MUST understand the available operators and their usage contexts to correctly interpret user requests and generate valid XML.
	*   **Operator Types:** Conditions generally involve a Left Hand Side (LHS), an Operator, and often a Right Hand Side (RHS). The main operator types are:
		*   **Pattern Matching (Simple Matching):** This is the default for text comparisons in many contexts (like Event/State parameters, Variable Value state, If action condition with `~` (Matches) or `!~` (Doesn't Match)).
			*   It compares the LHS against the RHS pattern.
			*   The `*` pattern on the RHS matches *anything*.
			*   A non-blank pattern must match the *entire* LHS value unless wildcards are used.
			*   `/` acts as an OR separator (e.g., `Value1/Value2` matches if LHS is exactly `Value1` OR `Value2`).
			*   `*`: Matches *zero or more* of any character (e.g., `*end` matches `legend` and `end`).
			*   `+`: Matches *one or more* of any character (e.g., `start+` matches `starter` but not `start`). This means `If %var Matches +` is true only if `%var` is set and contains at least one character; it is false if `%var` is unset or set to an empty string.
			*   Case-Insensitive (Default): Matching ignores case (`hello` matches `HeLlO`).
			*   Case-Sensitive (Triggered by Uppercase): If the RHS pattern contains *any uppercase letter*, the entire match becomes case-sensitive (`Hello` matches `Hello` but not `hello`).
			*   `!`: Placed at the very start of the RHS pattern, it negates the result (e.g., `!*important*` matches if the LHS does *not* contain `important`). Cannot match a literal `!` at the start (use `*!` instead).
			*   **Caller Matching Specifics:** In contexts related to phone calls (e.g., 'Call Received' Event, 'Call' State), special patterns exist:
				*   `C:ANY`: Matches any number belonging to a contact.
				*   `C:FAV`: Matches any number belonging to a favorite/starred contact.
				*   `CG:groupmatch`: Matches any number belonging to a contact in a group matching `groupmatch` (Simple Matching rules apply to `groupmatch`).
				*   Otherwise, the standard Simple Matching rules are applied against *both* the caller's number *and* their contact name (if available).
		*   **Pattern Matching (Regex):** Used with `~R` (Matches Regex) or `!~R` (Doesn't Match Regex) operators.
			*   The RHS pattern is treated as a standard Java Regular Expression.
			*   Provides more powerful and precise pattern matching capabilities than Simple Matching.
		*   **String Equality:** Used for exact text comparison.
			*   `Equals String` (UI symbol: `eq`): True if LHS is exactly identical to RHS (case-sensitive).
			*   `Not Equals String` (UI symbol: `ne`): True if LHS is *not* exactly identical to RHS (case-sensitive).
		*   **Numeric Comparison:** **CRITICAL: These operators MUST ONLY be used for comparing numbers or variables expected to contain valid mathematical expressions.** They perform mathematical evaluation on both LHS and RHS.
			*   `Less Than` (UI symbol: `<`): True if LHS evaluates numerically to less than RHS.
			*   `Greater Than` (UI symbol: `>`): True if LHS evaluates numerically to greater than RHS.
			*   `Equals` (UI symbol: `=`): True if LHS evaluates numerically to be equal to RHS. Returns true if both LHS and RHS are empty/undefined. Returns false if only one is empty/undefined.
			*   `Not Equals` (UI symbol: `!=`): True if LHS evaluates numerically to be not equal to RHS. Returns false if both LHS and RHS are empty/undefined. Returns true if only one is empty/undefined.
			*   **WARNING:** If either LHS or RHS cannot be evaluated as a number (e.g., it's plain text like "hello"), these comparisons will likely return `false` or produce unexpected results. **Do NOT use these for comparing non-numeric strings; use `Equals String` or `Matches` instead.**
		*   **Mathematical Checks:** These also perform numeric evaluation on the LHS.
			*   `Even`: True if LHS evaluates to an even number.
			*   `Odd`: True if LHS evaluates to an odd number.
			*   **WARNING:** Returns `false` if the LHS cannot be evaluated as a number.
		*   **Variable State:** Checks if a variable is defined (has been assigned any value).
			*   `Set`: True if the variable named in LHS exists and has been assigned a value (even an empty string).
			*   `Not Set`: True if the variable named in LHS has not been assigned any value (is undefined).
	*   **XML Structure for Conditions (Actions/Variable Value State):**
		*   While most Profile contexts take arguments directly (like `<State>`, `<Event>`), and some contexts are distinct tags with direct children (`<Time>`, `<App>`), conditions within specific **Actions** (most notably `If` - code 37, `Wait Until` - code 35) and the **Variable Value State** (code 165) use a specific XML structure:
			*   `<ConditionList sr="if">`: Acts as a container for one or more conditions.
			*   `<Condition sr="c[Index]" ve="3">`: Represents a single comparison.
			*   `<lhs>`: Contains the Left Hand Side variable or value (e.g., `<lhs>%my_variable</lhs>`).
			*   `<op>`: Contains the **numeric code** for the comparison Operator (see list below).
			*   `<rhs>`: Contains the Right Hand Side value (e.g., `<rhs>Some Value</rhs>`). This tag is **omitted** for unary operators (Set, Not Set, Even, Odd).
		*   **Operator Codes (for `<op>` tag):**
			*   `0`: Equals String (`eq`, case-sensitive text)
			*   `1`: Not Equals String (`ne`, case-sensitive text)
			*   `2`: Matches Simple Pattern (`~`, glob/wildcard)
			*   `3`: Doesn't Match Simple Pattern (`!~`)
			*   `4`: Matches Regex (`~R`)
			*   `5`: Doesn't Match Regex (`!~R`)
			*   `6`: Less Than (`<`, numeric)
			*   `7`: Greater Than (`>`, numeric)
			*   `8`: Equals (`=`, numeric)
			*   `9`: Not Equals (`!=`, numeric)
			*   `10`: Even (numeric)
			*   `11`: Odd (numeric)
			*   `12`: Is Set (variable defined)
			*   `13`: Is Not Set (variable undefined)
		*   **Remember:** Operators 6-11 are **strictly numeric**. Use 0-3 for general string comparisons.
	*   **Boolean Logic (Combining Multiple Conditions in `<ConditionList>`):**
		*   When a `<ConditionList>` contains multiple `<Condition>` tags, they are linked by boolean logic tags placed *between* them.
        *   **Crucially, if a `<ConditionList>` contains N `<Condition>` elements (where N > 1), you MUST generate N-1 corresponding boolean connector elements (`<bool0>`, `<bool1>`, ..., `<bool{N-2}>`) immediately preceding the second, third, ..., Nth `<Condition>` element, respectively. The content of each `<boolN>` tag (e.g., `And`, `Or`, `Xor`) determines the logical operation between the preceding condition(s) and the following one, respecting the specified precedence rules.**
		*   **Operators (as tag content):** `And`, `Or`, `Xor`, `And2`, `Or2`, `Xor2` (Note: `And2` corresponds to `&+`, `Or2` to `|+`, `Xor2` to `X|+`). Example: `<bool0>And</bool0>`, `<bool1>Or2</bool1>`.
		*   **Symbols (for reference):** `&` (And), `|` (Or), `X|` (Xor), `&+` (And2), `|+` (Or2), `X|+` (Xor2).
		*   **Precedence (Evaluation Order):** Determines how complex conditions are evaluated. Operators are evaluated from HIGHEST precedence to LOWEST precedence.
			*   Highest: `And+` / `And2` (&+)
			*   Medium-High: `Or+` / `Or2` (|+)
			*   Medium: `Xor+` / `Xor2` (X|+)
			*   Medium-Low: `And` (&)
			*   Low: `Or` (|)
			*   Lowest: `Xor` (X|)
			*   (Example: In `CondA & CondB |+ CondC`, the `|+` / `Or2` is evaluated first, then the `&` / `And`.)
	*   **AI Guidance:** Choose the most appropriate operator based on the user's intent. Use `Equals String` for exact text matches, `Matches` (with `*`/`+`) for pattern/substring checks, and Regex (`~R`) for complex patterns. Use numeric operators (`<`, `>`, `=`, `!=`, `Even`, `Odd`) **strictly for numbers or mathematical expressions**. Use `Set`/`Not Set` when checking if a variable simply exists. When generating `If` actions or `Variable Value` states, use the `<ConditionList>` structure with the correct `<op>` codes. Understand boolean precedence when combining conditions. **CRITICAL TASK FLOW STYLE: Prioritize 'Early Returns' for Validation/Error Checks.** Instead of deeply nesting the main task logic within multiple `If`/`Else` blocks, prefer checking for failure conditions first. If a failure condition is met (e.g., required variable not set, input invalid), use actions inside the `If` block to handle the error, **which MUST include using a `Flash` action (code 548) to clearly inform the user about the specific error**, and then immediately `Stop` the task (code 137). Place the main task logic *after* these `If`/`End If` validation blocks. This keeps the core logic less indented and easier to follow.
    *   **Task Flow for Mutually Exclusive Cases:** When a task needs to perform different actions based on which *one* of several mutually exclusive conditions is met (e.g., checking an event variable like `%evtprm2` against multiple possible app packages, or checking a variable against several distinct values), **avoid deep nesting with `If/Else If/Else`**. Instead, implement a series of independent `If` blocks. Each block should check one specific condition (`If condition X`), perform the actions required *only* for that condition, and then close with `End If`. **Crucially, decide whether to include a `Stop` action (code 137) just before the `End If` based on the overall task logic:**
        *   **Include `Stop`:** If handling this specific condition should prevent any subsequent actions in the task from running (i.e., this is the final action for this logical path).
        *   **Omit `Stop`:** If there is common logic *after* the entire sequence of independent `If` blocks that needs to run regardless of which condition (if any) was met.
        This approach ensures that only the actions for the *first* matching condition run if `Stop` is used appropriately, or allows the task to continue to subsequent common logic if `Stop` is omitted. It maintains a flatter, more readable structure than deep nesting, especially for many conditions.
