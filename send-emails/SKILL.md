---
name: send-emails
description: Assists in drafting and formatting various types of emails for automated or manual sending, including advanced file attachments via Google Drive and mandatory test email verification.
---

When sending emails, ALWAYS use the following from addresses according to the user request:

1. user [at] work.example [dot] edu, if job email is requested.
2. user@example.com, if formal email is requested.
3. Otherwise, omit the from address (so it defaults to the default)

## Verify available tools
FIRST verify that you have available the tools of the google-workspace mcp. If you don't, inform the user that you don't and don't proceed with the request.

# Mandatory Two-Stage Verification Workflow (Test-First Protocol)

**CRITICAL MANDATE:** You MUST ALWAYS send a test email to `user@example.com` before sending any real production emails (whether sending a single email or multiple batch emails).

**ZERO-BYPASS RULE:** Direct production transmission without prior test email dispatch and explicit user approval is STRICTLY FORBIDDEN under all circumstances, even if the user asks to send directly.

```
+-----------------------------+
| 1. Draft Email & Payload    |
+-----------------------------+
               |
               v
+-----------------------------+
| 2. Send Test Email to       |
|    user@example.com    |
+-----------------------------+
               |
               v
+-----------------------------+
| 3. Discord Alert &          |
|    Interactive User Prompt  |
+-----------------------------+
         /           \
   [Approve]       [Reject/Revise]
       |                  |
       |                  v
       |       +---------------------+
       |       | 4. Apply Fixes &    |
       |       |    Send New Test    |
       |       +---------------------+
       v                  |
+---------------------+   |
| 5. Production Send  |<--+ (Loops until approved)
|    to Real Targets  |
+---------------------+
```

## Stage 1: Test Email Dispatch
1. **Target Address:** Always set recipient to `user@example.com`.
2. **Subject Tagging:** Prepend `[TEST]` to the subject using `format-test-subject` from `utils.nu`. Ensure all accents and special characters are stripped.
3. **Test Banner:** Prepend a markdown test banner at the top of the body using `format-test-body` from `utils.nu`:
   - **Target Recipient(s):** Intended real recipient(s).
   - **Target Subject:** Original subject line.
   - **Sender Profile:** Designated from address.
   - **Attachments:** Share links / attachment details.
   - **Notice:** Note that this is an automated test dispatch sent to `user@example.com`.
4. **Preserve Content:** Below the banner, retain the exact production body (markdown/embedded HTML) and the required signature.
5. **Batch Representation:** When sending to multiple recipients (bulk/mailing list), send a single representative test email to `user@example.com` with a summary of all target recipients via `format-batch-test-summary` from `utils.nu`.

## Stage 2: Interactive Approval Gate
1. **Discord Notification (MANDATORY):** Before prompting the user for approval, you MUST send a Discord notification using `to-discord $msg -p` to alert the user that input is required.
2. **Interactive Confirmation:** Prompt the user with the test email details (sent timestamp, subject, recipient `user@example.com`, target recipients, body preview, attachment status) and request explicit approval.
3. **Rejection & Revision Loop:**
   - If the user rejects the test email or requests revisions (changes to subject, text, HTML layout, attachments, or recipient list):
     - Apply the requested modifications.
     - Send a FRESH test email to `user@example.com`.
     - Re-prompt for user approval.
     - Production dispatch remains blocked until approval is granted.

## Stage 3: Production Transmission
1. Execute production send ONLY after receiving explicit approval.
2. Strip `[TEST]` from the subject line.
3. Remove the test banner from the email body (keep the intended body and signature).
4. Send the email(s) to the actual recipient(s) using the designated `from` address.
5. Output a concise summary report of sent messages.

# Subject
Never use accents or special vocal or consonants in the subject, like á and equivalents.

# Body
When the body is not simple text but in markdown format, sent the body as embedded html with proper formatting.

# Email attachments workflow
When asked to attach files, if it is not allowed by the Google Workspace MCP tools:
1. Create a folder within the `Public` directory in the root of Google Drive using the appropriate Google Workspace MCP tool. The folder must be named `yyyy_mm_dd_name` (where `name` corresponds to the subject/recipient).
2. Execute the file transfer and mounting sequence by using the `evaluate` tool to source `utils.nu` from the `send-emails` skill directory and call the `mount_and_transfer` function with the appropriate arguments. **ALWAYS** activate the `nushell-expert` skill before executing the first Nushell command.
- **Nushell Mandate**: **ALWAYS** activate the `nushell-expert` skill before executing any Nushell command or pipeline.
3. Include a share link to the created folder in the email body.

## HTML Email with Local Images (Manual-Hybrid Approach)
Since most email clients (including Gmail) strip base64 data URIs and external hosting can be unreliable, use the following protocol for reports containing plots:
1.  **Draft Creation:** Use the `gmail.createDraft` tool to generate the email with the full HTML content.
2.  **Manual Attachment:** Ask the user to manually open the draft in the Gmail interface.
3.  **Inline Insertion:** Ask the user to manually drag and drop the local image files into the draft body where placeholders are located.
4.  **Final Send:** Ask the user to manually send the email to ensure images are correctly embedded as CID attachments.

# Email signatures workflow

When sending emails, you MUST ALWAYS include the corresponding signature found in the `signatures` directory. Before sending any email, first read the appropriate signature file and append it to the email body according to the following rules:

1. If the from address is user [at] work.example [dot] edu, you MUST include the `send-gmail_work` signature, without the codeblock delimiters.
2. If the from address is user@example.com, you MUST include the `send-gmail_personal` signature, without the codeblock delimiters.
3. Otherwise, you MUST include the `send-gmail_alt` signature, without the codeblock delimiters.

NEVER send an email without first reading and including the appropriate signature file.

# Signatures
## send-gmail_work
```

Author Name

Department Chair
Department
Faculty
Work University
City, Country
<PROFILE_URL>
---
Email sent from the Google Workspace mcp server on Ubuntu 24.04

Special characters and accents have been ommited for system compatibility
```
## send-gmail_personal
```

Author Name

--- 
Email sent from the Google Workspace mcp server on Ubuntu 24.04

Special characters and accents have been ommited for system compatibility
```
## send-gmail_alt
```

Author Name
---
Email sent from the Google Workspace mcp server on Ubuntu 24.04

Special characters and accents have been ommited for system compatibility
```
