# Prerequisites & Google Cloud Setup Guide: cron-workdept-uploader

This guide explains the prerequisites and one-time setup steps required from the user to enable autonomous video uploads and thumbnail publishing to the **WORK DEPT** YouTube channel (`https://www.youtube.com/@workdept`).

---

## 1. Google Cloud Project Status (CLI Audit)

We audited your local `gcloud` CLI environment and discovered that **you do NOT need to create a new Google Cloud project**:

- **Active Google Account**: `user@example.com`
- **Existing Project**: `<GCP_PROJECT_ID>` (`google-mcp-server`, Project #`<GCP_PROJECT_NUMBER>`)
- **API Status**: `youtube.googleapis.com` (YouTube Data API v3) is **already enabled** on this project.
- **Client Credentials**: The OAuth 2.0 Client ID and Secret for this project are already configured in your Nushell environment (`$env.MY_ENV_VARS.api_keys.google.zed_mcp_server`).

---

## 2. Actions Needed in Google Cloud Console

Google security policies prohibit CLI tools from modifying external OAuth consent screens or adding test users.

### Step A: Add Test User (Completed)
Since the `@workdept` channel is under `user@example.com`:
1. In [Google Cloud Console OAuth Consent Screen](https://console.cloud.google.com/apis/credentials/consent?project=<GCP_PROJECT_ID>), under **Test users**, `user@example.com` is added.
2. This grants that specific Google account permission to authorize your app without triggering `403 access_denied`.

### Step B: Publishing Status — Keep in "Testing" Mode
Google now requires a live public homepage, a privacy policy URL, and domain ownership verification in Google Search Console to move an app to "Production". 

To avoid the overhead of setting up external websites and domain verification:
* **Keep the app in "Testing" mode.**
* Since `user@example.com` is configured as a **Test user**, authentication and video/thumbnail uploads to `@workdept` will work seamlessly.
* **Token Lifecycle**: In "Testing" mode, Google's OAuth refresh tokens remain valid for **7 days**. Whenever the token expires, running `yt-oauth-login workdept` (a quick 10-second browser approval) grants a fresh 7-day token. Given there are only ~11 videos in the staging folder (`to_upload`), this is completely practical and avoids all domain verification hurdles.

---

## 3. YouTube Studio Channel Verification (Intermediate Features)

For custom thumbnail uploads via API (`thumbnails.set`), YouTube requires the target channel to have **Intermediate features** enabled. If this is not enabled, the API will fail with a `403 Forbidden` (`thumbnailDisabled`).

1. Log in to [YouTube Studio](https://studio.youtube.com) with the account managing `@workdept`.
2. Make sure you are switched to the **WORK DEPT** channel.
3. Go to **Settings** (gear icon in the bottom-left menu) -> **Channel** -> **Feature eligibility**.
4. Check **Intermediate features** (requires standard phone number SMS/call verification):
   - If it says **Enabled**, you are good to go.
   - If it is **Eligible** but not enabled, click the dropdown and verify a phone number.

---

## 4. One-Time Interactive OAuth Consent Flow

Once the multi-account command `yt-oauth-login` is implemented in `my_scripts/nushell/yt_api.nu`:

1. Open Nushell in your terminal:
   ```nu
   yt-oauth-login workdept
   ```
2. The command will output a Google OAuth URL. Copy and open it in your browser.
3. Sign in with the account managing `@workdept`.
4. If a screen says *"Google hasn't verified this app"*, click **Advanced** -> **Go to google-mcp-server (unsafe)**.
5. If you manage multiple channels or Brand Accounts, select the **WORK DEPT** (`@workdept`) channel.
6. Check all permissions:
   - *Manage your YouTube videos* (`youtube.upload` and `youtube.force-ssl`)
   - *View your YouTube account*
7. After clicking Allow, the browser will redirect to a localhost address (e.g., `http://localhost:8080/?code=4/0A...&state=...`).
8. Copy the full redirect URL from your browser's address bar and paste it back into the terminal prompt.
9. Nushell will exchange the code for tokens and save them to `~/.youtube_oauth_token_workdept.json`.

---

## 5. Verification & Checking Token Status

Check the status of your accounts at any time:

```nu
yt-api status        # Checks personal account (username)
yt-api status --ies  # Checks WORK DEPT channel account (@workdept)
```

Each command prints a clear overview for the selected account:
- **Token file location** and existence
- **Access token & refresh token status** (valid, expired, or time remaining)
- If expired or missing, an explicit instruction on how to re-authenticate (e.g. `Run: yt-oauth-login` or `Run: yt-oauth-login workdept`).

Additionally, your `/home/username/workspace/my_scripts/nushell/config.nu` includes a pre-execution hook that alerts you in the terminal whenever either account needs authentication.

You can test getting a valid Bearer token directly:

```nu
yt-get-access-token workdept
```

If it returns a valid token string, setup is complete!
