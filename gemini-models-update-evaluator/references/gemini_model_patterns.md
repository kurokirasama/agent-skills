# Gemini Model Patterns & Configuration Guide

This reference documents the standard code patterns, variable conventions, and test structures used when integrating new Google Gemini models into the Nushell environment (`my_scripts/nushell`).

---

## 1. Core Variables & Model Catalog (`defs_default/ai_google.nu`)

The model catalog is centralized in `defs_default/ai_google.nu`:

```nu
# Default flagship model for general queries
export const last_gemini_model = "gemini-4-argon"

# Alias for multimodal and vision-focused requests
export const gemini_pro_vision = "gemini-4-argon"

# Full list of active, supported models in descending capability order
export const gemini_models = [
  "gemini-4-argon"
  "gemini-3.8-flash"
  "gemini-3.7-flash"
  "gemini-3.6-flash"
  "gemini-3.5-flash-lite"
  "gemini-3.1-pro"
  "gemini-pro-vision"
]
```

### Main Function Default Argument
```nu
export def google_ai [
  prompt?: string
  --model (-m): string@$gemini_models = "gemini-4-argon"
  ...
]
```

---

## 2. Token Ceiling Mappings

Modern Gemini models (Gemini 3 and 4) support up to 64,000 output tokens. Legacy models are capped at 8,192:

```nu
let max_output_tokens = match $model {
  $m if ($m =~ "gemini-4") => 64000
  $m if ($m =~ "gemini-3.8") => 64000
  $m if ($m =~ "gemini-3.7") => 64000
  $m if ($m =~ "gemini-3.6") => 64000
  $m if ($m =~ "gemini-3.5") => 64000
  $m if ($m =~ "gemini-3.1") => 64000
  _ => 8192
}
```

---

## 3. Shorthand Model Alias Resolution

Alias matching resolves shorthand inputs (e.g. `gemini-4` or `gemini-3.8`) to the canonical model ID:

```nu
let canonical_model = match $model {
  "gemini-4" => "gemini-4-argon"
  "gemini-3.8" => "gemini-3.8-flash"
  "gemini-3.7" => "gemini-3.7-flash"
  "gemini-3.6" => "gemini-3.6-flash"
  "gemini-3.5" => "gemini-3.5-flash-lite"
  "gemini-3.1" => "gemini-3.1-pro"
  "gemini-3.0" | "gemini-3" => "gemini-3.8-flash"
  "gemini-pro-vision" => $gemini_pro_vision
  _ => $model
}
```

---

## 4. Thinking Level & Reasoning Configuration

Gemini 3 and 4 models feature explicit reasoning configurations (`thinking_level`):

```nu
# Guard for temperature deprecation warning
if ($model =~ "gemini-3" or $model =~ "gemini-4") and ($temperature != null) {
  # Notify user regarding fixed reasoning temperature
}

# Thinking level parameter construction
let thinking_config = if ($model =~ "gemini-3" or $model =~ "gemini-4") {
  if ($thinking_level != null) {
    { thinking_level: $thinking_level }
  } else {
    null
  }
} else {
  null
}
```

---

## 5. Downstream Consumer Files

1. **`defs_default/agents.nu`**:
   Must mirror `export const gemini_models`:
   ```nu
   export const gemini_models = [
     "gemini-4-argon"
     "gemini-3.8-flash"
     ...
   ]
   ```

2. **`env_vars.nu`**:
   Update `gemini_model_to_use` in `$env.MY_ENV_VARS`:
   ```nu
   gemini_model_to_use: "gemini-4-argon"
   ```

3. **`conductor/tech-stack.md`**:
   Update active model descriptions, default models, and token limits.

4. **`README.md`**:
   Update command line examples and default model highlights.

---

## 6. Verification Test Patterns (`tests/test_ai_google.nu`)

```nu
use std assert

# Assert default constant values
assert ($last_gemini_model == "gemini-4-argon") "Incorrect last_gemini_model"
assert ($gemini_pro_vision == "gemini-4-argon") "Incorrect gemini_pro_vision"

# Assert model catalog contents
assert ("gemini-4-argon" in $gemini_models) "gemini-4-argon missing from catalog"
assert ("gemini-3.5-flash" not-in $gemini_models) "Deprecated model still in catalog"

# Assert alias resolutions
assert ((resolve-gemini-alias "gemini-4") == "gemini-4-argon") "gemini-4 alias failed"
assert ((resolve-gemini-alias "gemini-3.8") == "gemini-3.8-flash") "gemini-3.8 alias failed"
```
