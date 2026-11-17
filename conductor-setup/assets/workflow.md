# Project Workflow

### Mandatory Protocols

#### Nushell-First Guidelines
Priority must be given to using Nushell pipelines and the `evaluate` tool for all system interactions and data manipulation tasks. **ALWAYS** activate the `nushell-expert` skill before executing the first nushell command you intend to use in the corresponding session. When writing Nushell codeblocks in markdown documents (plans, specs, READMEs, logs, or reports), always format them as ` ```nu ` instead of ` ```nushell `.

#### Status Reporting & Notifications

##### Standard Task Summary
After every successful task completion, provide a very brief summary in English of what was done and how.
- **Tone:** Conceptual description, including technical details only where appropriate for clarity.
- **Exception:** Do NOT provide a summary for trivial tasks unless explicitly requested.

##### Mandatory Discord Notification for User Input (CRITICAL)
Whenever you are about to use the `ask_user` (or equivalent) tool to request feedback, clarification, or approval, you **MUST** first send a Discord notification. This ensures the user is alerted that the agent is blocked and waiting for input.

**CRITICAL:** ALWAYS execute `to-discord` nushell command and WAIT for it to finish BEFORE executing the `ask_user` tool. This sequential ordering is mandatory to ensure the user is notified that the agent is blocked and waiting.

- **Notification Content**:
    - **Exact Question**: Include the literal question(s) being that will be asked via `ask_user` (or equivalent).
    - **Task Metadata**: State the current Track ID, Phase Name, and Task Description.
    - **Context for Review/Opinion**: If asking for a review or opinion on changes:
        - List the modified files.
        - Provide a high-level conceptual summary of the changes.
        - Include a simplified `git diff` (markdown code block ````diff````) focusing on relevant logic.
        - **Visibility Mandate**: The exact same information sent to Discord (question, metadata, context) MUST also be explicitly included in the `ask_user` call (or equivalent) so it is visible to the user in the chat interface.
        - **Diff Management**: If the diff or total message exceeds 2000 characters, split it into several messages.

- **Command**: Execute the nushell `evaluate` tool with `to-discord $message -p`.

- **Command**: Execute the `mcp_standard-nushell_evaluate` tool with `to-discord $message -p`.
- **Nushell Command**: `to-discord` is a Nushell command.
- **Nushell Activation**: **ALWAYS** activate the `nushell-expert` skill before executing the first nushell command.
- **Fallback Mechanism**: If the `evaluate` tool is unavailable or fails, use the following syntax to ensure local config/env are loaded:
  `nu --config /home/username/.config/nushell/config.nu --env-config /home/username/.config/nushell/env.nu -c 'to-discord "<message>" -p'`
- **Timing**: Send the notification **immediately before** calling `ask_user`.
- **`ask_user` Fallback**: If the `ask_user` tool is unavailable or not accessible in the current environment, ask the user directly by outputting your question as plain text in the chat interface.

##### Discord Notification for Long Tasks (5min+)
If a task takes 5 minutes or more, you **MUST** perform these steps before proceeding or asking for input:
1.  **Draft Report (English)**: Create a concise conceptual and technical summary, immediate next steps, and status (waiting for user or continuing automatically).
2.  **Send via Discord**: Execute the `mcp_standard-nushell_evaluate` tool with `to-discord $message -p`.
3.  **Sequence Priority**: If the next step involves `ask_user`, follow the "Mandatory Discord Notification for User Input" protocol above.

#### Track Management
- **Cleanup & Synchronization**: Once a track is archived or deleted, the agent **MUST** activate the `git-sync` skill to ensure the local repository is fully synchronized (pull/push loop) with the remote origin. This is a non-optional MUST to ensure the remote origin is synchronized immediately after cleanup operations.
- **Session Retrospective**: The `session-retro` skill MUST be executed when done if an issue was encountered that is new (compared against obsidian memory), required significant effort, or was interesting/unique.

## Guiding Principles

1. **The Plan is the Source of Truth:** All work must be tracked in `plan.md`
2. **The Tech Stack is Deliberate:** Changes to the tech stack must be documented in `tech-stack.md` *before* implementation
3. **Test-Driven Development (TDD):** Write unit tests before implementing functionality
4. **BDD / Gherkin Acceptance Scenarios:** Define functional specifications using `Given-When-Then` scenarios in `spec.md`
5. **High Code Coverage:** Aim for >80% code coverage for all modules
6. **Mutation Testing:** Use mutation testing (e.g., mutmut, Stryker, cargo-mutants) to verify test assertion quality, targeting a `>70%` Mutation Score on new/modified code.
7. **User Experience First:** Every decision should prioritize user experience
8. **Non-Interactive & CI-Aware:** Prefer non-interactive commands. Use `CI=true` for watch-mode tools (tests, linters) to ensure single execution.

## Task Workflow

All tasks follow a strict lifecycle:

### Standard Task Workflow

1. **Select Task:** Choose the next available task from `plan.md` in sequential order.

2. **Mark In Progress:** Before beginning work, edit `plan.md` and change the task from `[ ]` to `[~]`.

3. **Consult howto.md:** Read the relevant section of the track's `howto.md` for per-task implementation guidance (code snippets, patterns, pitfalls, verification commands). The agent MAY update `howto.md` during implementation if better approaches are discovered.

4. **Context Discovery & Sequential Thinking (Mandatory):**
   - Use `context-expert` for a systematic discovery phase, leveraging both internal codebase analysis and external MCP-based research.
   - **MANDATORY:** Activate the `sequentialthinking` tool for complex problem-solving, design, or when multiple solution attempts have failed.

5. **Write Failing Tests (Red Phase):**
   - Create a new test file for the feature or bug fix.
   - Write unit tests that implement the executable BDD/Gherkin scenarios specified in `spec.md`.
   - **CRITICAL:** Run the tests and confirm that they fail as expected. This is the "Red" phase of TDD. Do not proceed until you have failing tests.

6. **Implement to Pass Tests (Green Phase):**
   - Write the minimum amount of application code necessary to make the failing tests pass.
   - Run the test suite again and confirm that all tests now pass. This is the "Green" phase.

7. **Refactor (Optional but Recommended):**
   - With the safety of passing tests, refactor the implementation code and the test code to improve clarity, remove duplication, and enhance performance without changing the external behavior.
   - Rerun tests to ensure they still pass after refactoring.

8. **Verify Coverage and Run Mutation Tests:**
   - Run coverage reports using the project's chosen tools. Target: >80% coverage for new code.
   - Run the project's mutation testing suite (e.g. `mutmut`, `stryker`, or `cargo-mutants`) on the modified modules. Target a Mutation Score of `>70%`. If any mutants survive, add tests with stronger assertions to kill them.

9. **Skill Validation (if applicable)**: If the task involved creating or modifying a Gemini CLI Skill, you MUST validate it using the audit script and ensure it passes all criteria:
   ```bash
   nu scripts/audit-skill.nu <skill_path>
   ```

- **Status Reporting & Notifications:**
  - **Mandatory Notification for User Input (CRITICAL):** Whenever you are about to use the `ask_user` tool to request feedback, clarification, or approval, you **MUST** first send a Discord notification. This ensures the user is alerted that the agent is blocked and waiting for input.
    1. **Draft Notification Content**:
       - **Exact Question**: Include the literal question(s) being asked via `ask_user`.
       - **Task Metadata**: State the current Track ID, Phase Name, and Task Description.
       - **Context for Review/Opinion**: If asking for a review or opinion on changes:
         - List the modified files.
         - Provide a high-level conceptual summary of the changes.
         - Include a simplified `git diff` (markdown code block ````diff`) focusing on relevant logic.
    2. **Diff Management**: If the diff or total message exceeds 2000 characters, split it into several messages.
    3. **Send via Discord**: Send it via the `mcp_standard-nushell_evaluate` tool using `to-discord $message -p`.
    - **Fallback Mechanism**: If the `evaluate` tool is unavailable or fails, use the following syntax to ensure local config/env are loaded:
      `nu --config /home/username/.config/nushell/config.nu --env-config /home/username/.config/nushell/env.nu -c 'to-discord "<message>" -p'`
    - **Nushell Activation**: **ALWAYS** activate the `nushell-expert` skill before executing the first nushell command.
    4. **Timing**: Ensure the notification is sent **before** triggering the `ask_user` call.
    - **`ask_user` Fallback**: If the `ask_user` tool is unavailable or not accessible in the current environment, ask the user directly by outputting your question as plain text in the chat interface.
  - **Discord Notification for Long Tasks:** If a task takes **5 minutes or more**, you MUST:
    1. Draft a concise conceptual and technical report in English.
    2. Send it via the `mcp_standard-nushell_evaluate` tool using `to-discord $message -p`.
    - **Fallback Mechanism**: If the `evaluate` tool is unavailable or fails, use the following syntax to ensure local config/env are loaded:
      `nu --config /home/username/.config/nushell/config.nu --env-config /home/username/.config/nushell/env.nu -c 'to-discord "<message>" -p'`
    - **Nushell Activation**: **ALWAYS** activate the `nushell-expert` skill before executing the first nushell command.
    3. If the next step involves `ask_user`, prioritize the "Mandatory Notification for User Input" protocol above.


11. **Document Deviations**: If implementation differs from tech stack:
   - **STOP** implementation
   - Update `tech-stack.md` with new design
   - Add dated note explaining the change
   - Resume implementation

12. **Commit Code Changes:**
   - Stage all code changes related to the task.
   - Propose a clear, concise commit message authored as a human developer (e.g., `feat: Create basic HTML structure`).
   - **CRITICAL:** Never use `(conductor)` references or any other labels that identify the author as an AI. Always act as a human developer.
   - Perform the commit.

13. **Attach Task Summary with Git Notes:**
   - **Step 13.1: Get Commit Hash:** Obtain the hash of the *just-completed commit* (`git log -1 --format="%H"`).
   - **Step 13.2: Draft Note Content:** Create a detailed summary for the completed task. This should include the task name, a summary of changes, a list of all created/modified files, and the core "why" for the change.
   - **Step 13.3: Attach Note:** Use the `git notes` command to attach the summary to the commit.
     ```bash
     git notes add -m "<note content>" <commit_hash>
     ```

14. **Get and Record Task Commit SHA:**
    - **Step 14.1: Update Plan:** Read `plan.md`, find the line for the completed task, update its status from `[~]` to `[x]`, and append the first 7 characters of the *just-completed commit's* commit hash.
    - **Step 14.2: Write Plan:** Write the updated content back to `plan.md`.

15. **Commit Plan Update:**
    - **Action:** Stage the modified `plan.md` file.
    - **Action:** Commit this change with a descriptive message (e.g., `chore(plan): Mark task 'Create user model' as complete`).

### Phase Completion Verification and Checkpointing Protocol

**Trigger:** This protocol is executed immediately after a task is completed that also concludes a phase in `plan.md`.

1.  **Announce Protocol Start:** Inform the user that the phase is complete and the verification and checkpointing protocol has begun.

2.  **Ensure Test Coverage for Phase Changes:**
    -   **Step 2.1: Determine Phase Scope:** To identify the files changed in this phase, you must first find the starting point. Read `plan.md` to find the Git commit SHA of the *previous* phase's checkpoint. If no previous checkpoint exists, the scope is all changes since the first commit.
    -   **Step 2.2: List Changed Files:** Execute `git diff --name-only <previous_checkpoint_sha> HEAD` to get a precise list of all files modified during this phase.
    -   **Step 2.3: Verify and Create Tests:** For each file in the list:
        -   **CRITICAL:** First, check its extension. Exclude non-code files (e.g., `.json`, `.md`, `.yaml`).
        -   For each remaining code file, verify a corresponding test file exists.
        -   If a test file is missing, you **must** create one. Before writing the test, **first, analyze other test files in the repository to determine the correct naming convention and testing style.** The new tests **must** validate the functionality described in this phase's tasks (`plan.md`).

3.  **Execute Automated Tests with Proactive Debugging:**
    -   Before execution, you **must** announce the exact shell command you will use to run the tests.
    -   **Example Announcement:** "I will now run the automated test suite to verify the phase. **Command:** `CI=true npm test`"
    -   Execute the announced command.
    -   If tests fail, you **must** inform the user and begin debugging. You may attempt to propose a fix a **maximum of two times**. If the tests still fail after your second proposed fix, you **must stop**, report the persistent failure, and ask the user for guidance.

4.  **Propose a Detailed, Actionable Manual Verification Plan:**
    -   **CRITICAL:** To generate the plan, first analyze `product.md`, `product-guidelines.md`, and `plan.md` to determine the user-facing goals of the completed phase.
    -   You **must** generate a step-by-step plan that walks the user through the verification process, including any necessary commands and specific, expected outcomes.
    -   The plan you present to the user **must** follow this format:

        **For a Frontend Change:**
        ```
        The automated tests have passed. For manual verification, please follow these steps:

        **Manual Verification Steps:**
        1.  **Start the development server with the command:** `npm run dev`
        2.  **Open your browser to:** `http://localhost:3000`
        3.  **Confirm that you see:** The new user profile page, with the user's name and email displayed correctly.
        ```

        **For a Backend Change:**
        ```
        The automated tests have passed. For manual verification, please follow these steps:

        **Manual Verification Steps:**
        1.  **Ensure the server is running.**
        2.  **Execute the following command in your terminal:** `curl -X POST http://localhost:8080/api/v1/users -d '{"name": "test"}'`
        3.  **Confirm that you receive:** A JSON response with a status of `201 Created`.
        ```

5.  **Await Explicit User Feedback OR Execute Autonomously:**
    -   **Automated Verification:** Evaluate the generated plan against the **Automated Manual Verification Protocol**. If ALL steps are "simple" (Read-Only, Non-Destructive, Fast), the agent **MUST execute them autonomously**, attempt one Auto-Fix & Retry on failure, and proceed to step 6 on success.
    -   **Manual Verification:** If any step requires human validation (e.g., visual checks, destructive actions), present the detailed plan and ask the user for confirmation: "**Does this meet your expectations? Please confirm with yes or provide feedback on what needs to be changed.**"
    -   **PAUSE** and await the user's response. Do not proceed without an explicit yes or confirmation.

6.  **Create Checkpoint Commit:**
    -   Stage all changes. If no changes occurred in this step, proceed with an empty commit.
    -   Perform the commit with a clear and concise message (e.g., `chore(checkpoint): Checkpoint end of Phase X`).

7.  **Attach Auditable Verification Report using Git Notes:**
    -   **Step 7.1: Draft Note Content:** Create a detailed verification report including the automated test command, the manual verification steps, and the user's confirmation.
    -   **Step 7.2: Attach Note:** Use the `git notes` command and the full commit hash from the previous step to attach the full report to the checkpoint commit.

8.  **Get and Record Phase Checkpoint SHA:**
    -   **Step 8.1: Get Commit Hash:** Obtain the hash of the *just-created checkpoint commit* (`git log -1 --format="%H"`).
    -   **Step 8.2: Update Plan:** Read `plan.md`, find the heading for the completed phase, and append the first 7 characters of the commit hash in the format `[checkpoint: <sha>]`.
    -   **Step 8.3: Write Plan:** Write the updated content back to `plan.md`.

9. **Commit Plan Update:**
    - **Action:** Stage the modified `plan.md` file.
    - **Action:** Commit this change with a descriptive message following the format `chore(plan): Mark phase '<PHASE NAME>' as complete`.

10.  **Announce Completion:** Inform the user that the phase is complete and the checkpoint has been created, with the detailed verification report attached as a git note.

### Track Cleanup & Synchronization Protocol (conductor-finish-track / git-sync)

**CRITICAL:** When finishing a track, the agent SHOULD invoke the `conductor-finish-track` skill (`/conductor-finish-track`). This verifies completion/review, moves the track to `conductor/archive/<track_id>`, cleans the registry, and dispatches parallel subagents (or sequential fallback) for:
1. **Track Archival & Git Synchronization**: Moving the track, updating `metadata.json`, cleaning `tracks.md`, and executing `git-sync` to synchronize with remote origin.
2. **Long-Term Memory & Retrospective Update**: Activating `longterm-memory-orchestrator` (or `@memory-expert`), logging trajectories via `write-trajectory-log`, updating episodic memory in `AGENTS_MEMORY/`, and evaluating `session-retro` triggers.

Once a track is archived or deleted, the repository MUST be fully synchronized (pull/push loop) with the remote origin via `git-sync`.

#### Track Archival Memory Update Protocol (longterm-memory)

**CRITICAL:** After archiving or completing a track, the agent MUST follow this ordered protocol (handled automatically by `conductor:finish-track`):
1. Execute `git-sync` to synchronize the remote origin
2. Activate `longterm-memory-orchestrator` skill (or spawn `@memory-expert`)
3. Follow the orchestrator's guidance to activate `longterm-memory-writer`
4. Use `longterm-memory-writer`'s `write-trajectory-log` function to persist a trajectory log of the session
5. Evaluate `session-retro` triggers for newly discovered lessons or high-effort resolutions

This ensures that track completion, key decisions, outcomes, lessons learned, and the session trajectory are recorded in the project's episodic memory.

### Automated Manual Verification Protocol

When a workflow or task requires manual verification (e.g., Phase Completion, Quality Gates), the agent **MUST** evaluate if the verification steps are "simple".
A verification step is "simple" if it is:
- **Read-Only**: Does not modify the codebase or critical system state.
- **Non-Destructive**: Safe to execute as a background process or standalone check.
- **Fast Execution**: Expected to complete quickly.
- **Examples**: Checking file contents, executing scripts (tests, linters), analyzing stdout/stderr or log files.

If the verification steps meet these criteria, the agent **MUST execute these steps autonomously** instead of asking the user for confirmation.
- **Fallback & Error Handling**: If an automated verification step fails, the agent must attempt an **Auto-Fix & Retry once**. If the retry fails, it must halt and ask the user for manual intervention.
- **Logging**: All automated verification outcomes must be clearly documented in the task or phase summaries and git notes.

**Manual Verification Steps Example:**

1. **For a Frontend Change:**
   ```
   The automated tests have passed. For manual verification, please follow these steps:

   **Manual Verification Steps:**
   1.  **Start the development server with the command:** `npm run dev`
   2.  **Open your browser to:** `http://localhost:3000`
   3.  **Confirm that you see:** The new user profile page, with the user's name and email displayed correctly.
   ```

2. **For a Backend Change:**
   ```
   The automated tests have passed. For manual verification, please follow these steps:

   **Manual Verification Steps:**
   1.  **Ensure the server is running.**
   2.  **Execute the following command in your terminal:** `curl -X POST http://localhost:8080/api/v1/users -d '{"name": "test"}'`
   3.  **Confirm that you receive:** A JSON response with a status of `201 Created`.
   ```

### Quality Gates

Before marking any task complete, verify:

- [ ] All tests pass
- [ ] Code coverage meets requirements (>80%)
- [ ] Code follows project's code style guidelines (as defined in `code_styleguides/`, specifically [Skill Creation](./code_styleguides/skill_creation.md) and [Agent Creation](./code_styleguides/agent_creation.md))
- [ ] All public functions/methods are documented (e.g., docstrings, JSDoc, GoDoc)
- [ ] Type safety is enforced (e.g., type hints, TypeScript types, Go types)
- [ ] No linting or static analysis errors (using the project's configured tools)
- [ ] Works correctly on mobile (if applicable)
- [ ] Documentation updated if needed
- [ ] No security vulnerabilities introduced



## Development Commands

**AI AGENT INSTRUCTION: This section should be adapted to the project's specific language, framework, and build tools.**

### Daily Development
```bash
# Example: Commands for common daily tasks (e.g., start dev server, run tests, lint, format)
# e.g., for a Node.js project: npm run dev, npm test, npm run lint
# e.g., for a Go project: go run main.go, go test ./..., go fmt ./...
```

### Before Committing
```bash
# Example: Commands to run all pre-commit checks (e.g., format, lint, type check, run tests)
# e.g., for a Node.js project: npm run check
# e.g., for a Go project: make check (if a Makefile exists)
```

## Definition of Done

A task is complete when:
1. All code implemented to specification.
2. Unit tests written and passing.
3. Code coverage meets project requirements (>80%).
4. Core Protocols (Nushell-first, Memory Retrieval, Discord Notification) were followed.
5. Implementation notes added to `plan.md`.
6. Changes committed and documented with git notes.

## Emergency Procedures

### Critical Bug in Production
1. Create hotfix branch from main
2. Write failing test for bug
3. Implement minimal fix
4. Test thoroughly including mobile
5. Deploy immediately
6. Document in plan.md

### Security Breach
1. Rotate all secrets immediately
2. Review access logs
3. Patch vulnerability
4. Notify affected users (if any)
5. Document and update security procedures

## Deployment Workflow

### Pre-Deployment Checklist
- [ ] All tests passing
- [ ] Coverage >80%
- [ ] No linting errors
- [ ] Mobile testing complete
- [ ] Environment variables configured
- [ ] Database migrations ready
- [ ] Backup created

### Post-Deployment
1. Monitor analytics
2. Check error logs
3. Gather user feedback
4. Plan next iteration

## Continuous Improvement

- Review workflow weekly
- Update based on pain points
- Document lessons learned
- Optimize for user happiness
- Keep things simple and maintainable


## Commit Guidelines

When generating or proposing commit messages, you **MUST** consider the following:
- **Prohibited Patterns:** Never use `(conductor)` references or any other labels that identify the author as an AI (e.g., avoid `chore(conductor): ...`).