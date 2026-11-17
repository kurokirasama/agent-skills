---
name: gemini-api-skills
description: Smart router for Gemini API development. Dynamically loads and routes to sub-skills (vertex-ai-api-dev, gemini-api-dev, gemini-live-api-dev, gemini-interactions-api) from gemini-skills/skills/ based on context (Vertex, Cloud, Studio, Realtime, Interactions). Use sub-commands like :vertex or :studio for manual routing.
---

# Gemini API Skills Wrapper

This skill acts as a centralized gateway to the specialized Gemini API development skills.

## Operational Mandate

As the Gemini API Skills router, you MUST analyze the user's intent and context to activate the most appropriate specialized skill.

### 1. Automatic Routing (Contextual Activation)

If any of the following triggers are detected based on loaded sub-skill metadata from `gemini-skills/skills/`, you MUST immediately call `activate_skill(name: "<skill-name>")` before proceeding:

- **Trigger: Vertex AI / Google Cloud**
  - Loaded from: `vertex-ai-api-dev` sub-skill metadata
  - Keywords: "Vertex", "Google Cloud", "GCP", "Enterprise", "MLOps", "ADC", "Service Account", "Project ID", "v1beta1", "v1".
  - **Action**: `activate_skill(name: "vertex-ai-api-dev")`

- **Trigger: Gemini API (Google AI Studio)**
  - Loaded from: `gemini-api-dev` sub-skill metadata
  - Keywords: "AI Studio", "Gemini Developer API", "API Key", "google-genai" (without Vertex context).
  - **Action**: `activate_skill(name: "gemini-api-dev")`

- **Trigger: Live API / Real-time Streaming**
  - Loaded from: `gemini-live-api-dev` sub-skill metadata
  - Keywords: "Live API", "Realtime", "WebSocket", "Streaming", "Voice", "Video", "Bidi", "Multimodal Live".
  - **Action**: `activate_skill(name: "gemini-live-api-dev")`

- **Trigger: Conversations / Interactions**
  - Loaded from: `gemini-interactions-api` sub-skill metadata
  - Keywords: "Interaction", "Chat", "Conversational", "Session", "Multi-turn".
  - **Action**: `activate_skill(name: "gemini-interactions-api")`

### 2. Manual Routing (Sub-command Proxying)

If the user explicitly uses a sub-command or mentions a specific backend, activate the corresponding skill:

- `:studio` or mention of "AI Studio" -> `activate_skill(name: "gemini-api-dev")`
- `:vertex` or mention of "Vertex" -> `activate_skill(name: "vertex-ai-api-dev")`
- `:live` or mention of "Live API" -> `activate_skill(name: "gemini-live-api-dev")`
- `:interactions` or mention of "Interactions API" -> `activate_skill(name: "gemini-interactions-api")`

## Sub-Skills Registry

The following specialized skills are managed by this router and located in `gemini-skills/skills/`:

### gemini-api-dev
- **Path**: `gemini-skills/skills/gemini-api-dev/SKILL.md`
- **Description**: Gemini API development for Google AI Studio. Covers SDK usage, model selection, multimodal content, function calling, structured outputs, and API capabilities.
- **Triggers**: "AI Studio", "Gemini Developer API", "API Key", "google-genai"

### vertex-ai-api-dev
- **Path**: `gemini-skills/skills/vertex-ai-api-dev/SKILL.md`
- **Description**: Gemini API on Google Cloud Vertex AI. Covers enterprise configuration, unified SDK with vertexai=True, Live API, tools, multimedia generation, caching, and batch prediction.
- **Triggers**: "Vertex", "Google Cloud", "GCP", "Enterprise", "MLOps", "ADC", "Service Account"

### gemini-live-api-dev
- **Path**: `gemini-skills/skills/gemini-live-api-dev/SKILL.md`
- **Description**: Real-time bidirectional streaming with Gemini Live API. Covers WebSocket audio/video/text streaming, VAD, native audio, function calling, session management, ephemeral tokens.
- **Triggers**: "Live API", "Realtime", "WebSocket", "Streaming", "Voice", "Video", "Bidi"

### gemini-interactions-api
- **Path**: `gemini-skills/skills/gemini-interactions-api/SKILL.md`
- **Description**: Recommended way to use Gemini models and agents in Python/TypeScript. Covers Interactions API, text generation, multi-turn chat, multimodal understanding, image generation, streaming, function calling, structured output.
- **Triggers**: "Interaction", "Chat", "Conversational", "Session", "Multi-turn"

## Mandatory Sub-Skills Loading

At activation, this skill MUST load sub-skill definitions from `gemini-skills/skills/` by:
1. Scanning the directory for sub-directories containing `SKILL.md` files
2. Reading each `SKILL.md` to extract frontmatter `name` and `description` fields
3. Using this dynamically loaded metadata for routing decisions
4. Caching loaded definitions for performance (reload on next activation)

If a sub-skill is missing required frontmatter fields, log a warning but continue with available skills.

## Skill Discovery Protocol

The router discovers sub-skills by:
1. **Scan**: List directories in `gemini-skills/skills/`
2. **Validate**: For each directory, check for `SKILL.md` file
3. **Extract**: Parse frontmatter for `name` and `description` fields
4. **Register**: Add to internal routing table
5. **Cache**: Store for session duration (reload on next activation)

**Validation Rules**:
- Sub-skill directory must contain `SKILL.md`
- Frontmatter must have `name` (string) and `description` (string)
- If validation fails, log warning and skip that sub-skill

**Future-Proofing**: New sub-skills added to `gemini-skills/skills/` are automatically discovered on next activation without requiring router updates.

## Usage Guidelines

- **Silent Activation**: Once a specialized skill is activated, follow its specific mandates and rules. You do not need to announce the activation unless it helps the user understand the context shift.
- **Preference for Unified SDK**: Note that both Vertex AI and AI Studio now use the unified `google-genai` SDK. Use the specialized skill to determine the correct configuration (e.g., `vertexai=True` vs. API Key).
- **Dynamic Routing**: Automatic routing decisions are powered by the sub-skill metadata loaded from `gemini-skills/skills/`. The triggers listed below correspond to the registered sub-skills.