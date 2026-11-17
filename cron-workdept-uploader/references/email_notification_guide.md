# Email Notification Guide: WORK DEPT Uploader

This guide documents the autonomous email notification protocol executed after successful live uploads in the `cron-workdept-uploader` skill.

---

## 1. From-Address Mechanics

### MCP Fallback in `dist/index.js`
The Google Workspace MCP extension (`~/.gemini/extensions/google-workspace/dist/index.js`) handles email dispatch. In standard CLI environments, the `from` parameter is often stripped or omitted from the tool call schema by primary models, defaulting to the hardcoded server fallback:
```javascript
let sender = I || "user@work.example.edu";
```
By patching `dist/index.js` on execution hosts to default to the institutional job email (`user@work.example.edu`), all emails dispatched without an explicit `from` argument originate from the intended sender.

### Per-Machine State Table
| Machine | Hostname | Role | MCP Fallback | Web Send-As Default |
|---|---|---|---|---|
| Workstation | `desktop` | Cron host (`0 14 * * 3`) & render machine | `user@work.example.edu` (patched) | `user@work.example.edu` |
| Laptop | `laptop` | Portable development workstation | `user@work.example.edu` (patched) | `user@work.example.edu` |

*Note: The Gmail web Send-As default MUST always remain `user@work.example.edu`.*

---

## 2. Test-First Protocol & Auto-Verification Gate

To guarantee that production emails never leak personal addresses (`user@example.com`), the skill enforces a mandatory test-first verification procedure.

### Step-by-Step Verification Flow
1. **Gate Check**: Inspect `state.json`. If `email_verified` is `false` (or missing):
   - Enter **Test-Only Mode**.
   - Send a test email to `user@example.com` with:
     - **Subject**: `[TEST] Nuevo video en canal de youtube de la carrera`
     - **Body Banner**: `[TEST EMAIL - VERIFYING FROM SENDER ADDRESS]` followed by the standard body.
2. **Sender Inspection**:
   - Retrieve the sent message details via `gmail.get` (and read recent inbox messages).
   - Inspect the `From` header value.
3. **Auto-Verification Gate (Auto-Approval)**:
   - If `From` matches `user@work.example.edu`:
     - Automatically update `state.json`: `"email_verified": true`.
     - Send an informational Discord notification for visibility:
       `✅ [cron-workdept-uploader] Sender verified as user@work.example.edu. Production email gate unlocked.`
     - **Proceed immediately to production notification in the same pulse.**
   - If `From` is NOT `user@work.example.edu`:
     - **HALT production notification immediately.**
     - Send a failure alert to Discord:
       `❌ [cron-workdept-uploader] Verification failed: From header was <actual_from>. Halting production send.`
     - Log error in `log.txt`. Do NOT email `colleague@work.example.edu`.

---

## 3. Production Email Contract & Template

When `state.json.email_verified` is `true`, dispatch the production notification after every successful live upload.

### Recipient & Headers
- **To**: `colleague@work.example.edu`
- **From**: `user@work.example.edu` (job email)
- **Subject**: `Nuevo video en canal de youtube de la carrera`

### Email Body Template
```text
Hola Angeles,

aca nuevo video subido al canal, <url>, para que puedas promocionarlo en instagram.

Saludos,

Author Name
Department Chair
Work University
```
*(Where `<url>` is substituted with `https://youtu.be/<video_id>` of the newly uploaded video).*

### Signature Compliance
The signature adheres to the `send-gmail_work` signature standard defined in the `send-emails` skill:
```text
Author Name
Department Chair
Work University
```

---

## 4. Failure Isolation & Resilience
- **Non-Blocking Guarantee**: Email dispatch failure must NEVER fail or rollback the video upload lifecycle.
- If email sending fails (e.g., API quota, network timeout):
  1. Record the error in `log.txt`.
  2. Output the warning to `stdout`.
  3. The upload remains marked as `completed` in `state.json`.
