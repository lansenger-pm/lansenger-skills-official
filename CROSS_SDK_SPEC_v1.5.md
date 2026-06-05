# Cross-SDK Change Specification — v1.5 Release

This document specifies the changes that must be synchronized across all Lansenger SDK implementations (Python, Go, TypeScript) and their corresponding CLIs.

**Reference implementation**: Python SDK v1.5.0 + CLI v0.10.0

---

## 1. UserTokenManager (Auto-Refresh)

### Problem
userToken expires in 2 hours. refreshToken is long-lived (30 days) but single-use (rotated on each refresh). Developers must manually track expiry and call `refresh_user_token()` with the latest refreshToken.

### Solution: UserTokenManager

Add a `UserTokenManager` class mirroring the existing `TokenManager` (appToken auto-refresh):

```
class UserTokenManager:
    - get_token() → returns valid userToken, auto-refreshes if expired (5 min margin)
    - set_tokens(user_token, refresh_token, expires_in, staff_id) → register tokens after exchange_code
    - invalidate() → force refresh on next call
    - staff_id property → staffId associated with current token
    - refresh_token property → current refreshToken (diagnostic)
    - Persists to CredentialStore after refresh (refreshToken rotation)
    - Raises AuthError if refreshToken expired (must re-authorize)
```

### Integration
- Client constructor: create `UserTokenManager` alongside `TokenManager`
- `exchange_code()` success → auto-register in UserTokenManager + persist
- New method: `client.get_user_token()` — auto-refresh
- New method: `client.set_user_tokens()` — manual registration
- Sync client: mirror with blocking wrappers

### CredentialStore Changes
- `load_user_token()` already returns `{user_token, refresh_token, user_token_expiry}`
- `save_user_token()` already accepts `expires_in` parameter
- **No changes needed** to CredentialStore

---

## 2. ChatMessageInfo.plain_text()

### Problem
ChatMessage `content` field has 4+ formats depending on msgType:
- `{"text": "xxx"}` (text)
- `{"formatText": {"content": "xxx"}}` (formatText)
- `{"text": "", "attachments": [...]}` (attachment)
- `"xxx"` (plain string)
- `None`

### Solution
Add `plain_text()` method to `ChatMessageInfo` (or equivalent model):

```python
def plain_text(self) -> str:
    content = self.content
    if content is None: return ""
    if isinstance(content, str): return content
    if isinstance(content, dict):
        if "text" in content and content["text"]: return content["text"]
        if "formatText" in content: return content["formatText"].get("content", "")
    return ""
```

---

## 3. CLI: oauth local-callback

### Problem
蓝信 OAuth2 redirect_uri must be a trusted domain. localhost is not trusted. Users must manually copy code from browser.

### Solution
New CLI subcommand: `oauth local-callback`

```
Starts a temporary HTTP server on localhost:<port>
Prints authorize URL with redirect_uri=http://localhost:<port>
Captures browser redirect (code from URL params)
Auto-exchanges code for userToken (optional with --no-exchange)
Shuts down server after callback received
```

Parameters:
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| --port / -p | int | 8765 | Local HTTP server port |
| --scope / -s | str | basic_userinfor | OAuth2 scope |
| --state | str | "" | CSRF state (auto-gen if empty) |
| --exchange / --no-exchange | bool | true | Auto-exchange code |
| --timeout / -t | int | 120 | Max wait seconds |

Note: Even if localhost is not in the trusted domain list, the browser still redirects to localhost URL. The page may show an error, but the URL contains the code parameter which the local server captures.

---

## 4. CLI: chat --split-month / --progress

### Problem
Chat message API silently drops older data when time range exceeds ~1 month.

### Solution
- `--split-month` flag: auto-split time range into monthly chunks
- `--progress` flag: show pagination progress during batch fetch
- Internal `_split_months()` helper to compute month boundaries

---

## 5. Bug Fix: exchange_code expires_in

### Problem
`exchange_code()` was not passing `expires_in` to `save_user_token()`, causing `user_token_expiry=0` in the store.

### Solution
Pass `result.expires_in` to `save_user_token()`:
```python
self._store.save_user_token(
    user_token=result.user_token,
    refresh_token=result.refresh_token,
    expires_in=result.expires_in,  # was missing
)
```

---

## 6. Other CLI Changes (already in v0.9.x)

These were already shipped in Python CLI but need syncing:

| Change | Description |
|--------|-------------|
| callback decrypt-payload | New subcommand + --callback-token, --known-app-id, --data-encrypt params |
| config VALID_KEYS | Added encoding_key + callback_token |
| calendar --rule/--expire/--attendee-perms | New params for create-schedule |
| calendar --reminder | New param for add/delete-attendees |
| message --content | Renamed from --caption in send-file/send-image-url |
| health/chat/oauth/media --json | Added --json output support |

---

## Implementation Priority

| Priority | Change | Effort |
|----------|--------|--------|
| **P0** | UserTokenManager | ~200 lines per SDK |
| **P0** | exchange_code expires_in fix | 1 line |
| **P1** | ChatMessageInfo.plain_text() | ~20 lines |
| **P1** | CLI local-callback | ~80 lines |
| **P1** | CLI --split-month/--progress | ~60 lines |
| **P2** | Other CLI changes (table above) | varies |