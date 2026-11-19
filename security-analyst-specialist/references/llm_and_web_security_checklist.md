# LLM, RAG & Web Security Audit Checklist

Reference checklist for `security-analyst-specialist`, `security-programmer-specialist`, and Dimension 2 of `conductor-review` (`prerelease_audit_protocol.md`). Designed for a **Report-First** defense-in-depth workflow.

---

## 1. AI / LLM & RAG Security Controls

| Control | Standard / Mitigation | Anti-Pattern to Flag |
| :--- | :--- | :--- |
| **Prompt Delimiters** | Wrap all untrusted user input and retrieved documents in distinct XML/JSON tags (`<user_input>...</user_input>`, `<retrieved_context>...</retrieved_context>`). | Direct Python f-strings or template interpolation of raw user prompts/code into system prompts. |
| **Immutable System Instructions** | Keep core system behavioral rules as static constants; never let user params or DB content override system role instructions. | Merging user settings or retrieved chunk headers directly into system instructions. |
| **Pre-Prompt PII Masking** | Strip or mask personal/confidential identifiers (`[EMAIL]`, `[ID]`, national IDs, API keys, internal host paths) via a dedicated `mask_pii` / Presidio pass before prompt assembly. | Passing raw email addresses, student/patient IDs, or filesystem paths directly to external LLM APIs. |
| **Input & Context Caps** | Enforce strict character/token limits per field and chunk count bounds to prevent resource exhaustion, API cost spikes, and long-context attacks. | Unbounded request payloads forwarded verbatim to model endpoints. |
| **Native API Safety Filters** | Explicitly configure provider safety filters at the API client level (Harassment, Hate Speech, Dangerous Content) matching application risk tolerance. | Relying solely on default or disabled safety filter thresholds. |
| **Output Sanitization** | Pass all LLM-generated HTML/Markdown through `DOMPurify` / `isomorphic-dompurify` (frontend) or `bleach` (Python) with a narrow tag allowlist (`<b>`, `<i>`, `<code>`, `<pre>`, `<a>`, `<ul>`, `<li>`). | Passing model responses straight to `dangerouslySetInnerHTML`, `unsafe_allow_html=True`, or unescaped `innerHTML`. |
| **Safe Error Handling** | Log full exception details/tracebacks only internally or in admin-only logs; return opaque generic error messages/IDs to end users. | Exposing raw stack traces, SQL errors, filesystem paths, or env var names in HTTP/UI responses. |

---

## 2. Web, API & Ingestion Security Controls

1. **Path Traversal (LFI) & Ingestion Safety:**
   - Resolve file paths canonically (`path.resolve(...)` in Node / `Path(p).resolve()` in Python) and assert `resolved.is_relative_to(allowed_root)` before any filesystem read/write or RAG ingestion.
   - Strip directory components (`os.path.basename`) and reject `..`, null bytes, and symlink escapes on uploads.
2. **Server-Side Request Forgery (SSRF) Prevention:**
   - Validate user-supplied URLs against a strict scheme (`https://` only in prod) and host/pattern allowlist before server-side fetching or Drive/external imports.
   - Block loopback (`127.0.0.1`, `::1`), link-local (`169.254.0.0/16` metadata endpoints), and RFC 1918 private subnets on outbound fetchers.
3. **Authentication, Sessions & Secrets:**
   - Fail closed in production if cookie/JWT secrets match development placeholders or fall back to static defaults.
   - Require `https://` on OAuth redirect URIs and API endpoints in production configs (`CORS` allowlist restricted to trusted origins, no `*` with `allow_credentials=True`).
   - Enforce RBAC server-side on every endpoint/action — never rely solely on UI visibility or hidden admin tabs.
4. **High-Sensitivity Local Data Sovereignty:**
   - For personal, clinical, or confidential counseling workflows stored locally, encrypt diaries/session archives at rest using symmetric GPG / `nu-crypt` loopback rather than plaintext markdown/JSON on cloud-synced folders.
5. **Supply-Chain & Dependency Auditing:**
   - Run stack auditors (`pip-audit`, `npm audit`, `cargo audit`) and remediate High/Critical CVEs.

---

## 3. Report-First `.gemini_security/` Audit Loop

Always document vulnerabilities **before** applying code fixes:

1. **Verify Historical Reports First:** Read any prior reports in `.gemini_security/` or `docs/*security*.md` to ensure previously mitigated vulnerabilities have not regressed.
2. **Write Dated Audit Artifact:** Save new findings to `.gemini_security/audit_report_YYYYMMDD.md` using the schema below:

```markdown
# Security Audit Report — YYYY-MM-DD

## Summary
- **Scope:** <files/modules/endpoints reviewed>
- **Result:** <CRITICAL: N | HIGH: N | MEDIUM: N | LOW: N>

## Findings

### VULN-001: <Short Title>
- **Severity:** Critical | High | Medium | Low
- **Category:** Prompt Injection | LFI | XSS | SSRF | Auth/Secrets | Information Leakage | CVE
- **Source Location:** `path/to/entry.py:L42`
- **Sink Location:** `path/to/sink.py:L108`
- **Impact:** <Concrete attacker capability or data exposure>
- **Remediation:** <Exact defensive fix>
- **Status:** OPEN | RESOLVED
```

3. **Approval Gate:** Notify via Discord (`to-discord $msg -p`) and obtain explicit user approval before modifying source files for `CRITICAL` / `HIGH` or architectural fixes.
4. **Patch & Regression Test:** Hand off approved fixes to `security-programmer-specialist`, mark `VULN-###` as `RESOLVED`, and add targeted regression tests.
