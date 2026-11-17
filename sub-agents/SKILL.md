---
name: sub-agents
description: Assists in delegating complex tasks to specialized sub-agents based on their expertise.
---

# Sub-Agents & Swarms Delegation Workflow

When decomposing complex, multi-faceted problems into logical sub-tasks, you must select the appropriate delegation vector based on the level of collaboration, state isolation, and resource intensity required.

## Delegation Architecture Hierarchy

Antigravity CLI provides two distinct delegation mechanisms:

| Delegation Mechanism | Tool / Interface | Best Used For | Communication | Quota Impact |
| :--- | :--- | :--- | :--- | :--- |
| **Focused Subagent** | `invoke_subagent`, `send_message` | Isolated, single-responsibility background tasks (e.g., codebase research, single file migration, independent calculation). | Direct 1:1 message with parent agent. | Moderate (single agent instance). |
| **Native Multi-Agent Swarm** | `swarm` native swarm tool, `/swarm <task>` | Collaborative, multi-perspective, or parallel implementation tasks (e.g., peer review referees, author-verifier TDD, multi-file feature builds). | Asynchronous shared message board (`post_message`, `read_board`, `swarm_wait`). | **Quota Heavy** (multiple concurrent agent instances). |

---

## 1. Focused Subagent Workflow (`invoke_subagent`)

Use `invoke_subagent` when a sub-task is self-contained and does not require active coordination with other peer subagents.

1. **Sub-Task Decomposition**: Break down the task into discrete, self-contained sub-tasks.
2. **Subagent Type & Model Selection**:
   - `research`: Read-only exploration of the codebase or documentation.
   - `self`: Inherits parent agent's full capabilities and write tools.
   - Specify `Model: "inherit"` unless a lightweight model (`flash_lite` / `flash`) is sufficient.
3. **Execution**: Call `invoke_subagent{TypeName, Role, Prompt, Workspace}`.
4. **Reactive Wakeup**: Do NOT poll in a loop; the system automatically wakes the coordinator when the subagent responds.
5. **Synthesis**: Receive deliverable via context and proceed.

---

## 2. Native Multi-Agent Swarm Workflow (`swarm` tool)

Use the native `swarm` tool when multiple agents need to collaborate concurrently, peer-review each other, or work simultaneously on separate repository targets.

### Pre-requisites & Mandatory Approval Gate
- **Quota Heavy Advisory**: Every swarm worker is a full LLM instance consuming quota from one of three pools (Gemini 3.x, Gemini 4, Claude/GPT).
- **Mandatory Approval Gate**: The coordinator must **NEVER** autonomously launch a swarm without explicit user confirmation. Always send a Discord notification (`to-discord $msg -p`), then prompt the user with:
  1. Swarm title and proposed roster (roles and model assignments).
  2. Workspace isolation mode for each worker.
  3. Clear definition of done.

### Swarm Lifecycle

1. **Initialization**:
   - Assign title: `swarm{action: "title", title: "<task_name>"}`.
   - Attach stall sentinel: Always add `monitor` running `swarm_monitor` in the initial turn.
   - Add workers: Add domain-specific workers (`swarm{action: "add", name: "<role>", workspace: "<mode>", brief: "..."}`).
2. **Workspace Isolation Guidelines**:
   - **`workspace: "share"`**: Mandatory for code/content authors modifying files concurrently. Preserves uncommitted/staged files in an isolated worktree without merge collisions.
   - **`workspace: "inherit"`**: Mandatory for verifiers, reviewers, and read-only researchers.
3. **Board Collaboration Loop**:
   - Technical work belongs to workers. The coordinator orchestrates, judges results, and reports to the user.
   - Address workers by name (`@<name>`), referencing earlier board messages by sequence (`#seq`).
   - Use `swarm_wait` to sleep until board posts arrive; do not poll in loops.
4. **Quota Pool Management**:
   - If a worker encounters quota exhaustion, alert the user to choose an alternative quota pool (e.g. Gemini 4 or Claude/GPT) or pause for reset. Do NOT blind-fallback within the same exhausted pool.
5. **Teardown & Landing**:
   - Merge or land author worktrees before calling `swarm{action: "kill"}`.
   - Report final deliverable to user with `[done] <summary>`.
