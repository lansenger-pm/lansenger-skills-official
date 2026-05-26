[English](README.md) | [简体中文](README.zhHans.md) | [繁体中文](README.zhHant.md) | [繁体中文（香港）](README.zhHantHK.md) | [Français](README.fr.md)

# lansenger-skills-official

AI Agent Skills for Lansenger CLI — structured Markdown skill docs for Python and Go CLI, covering messaging, calendar, groups, contacts, departments, todos, streaming, callbacks, OAuth, and more.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## What are Skills?

Skills are structured Markdown documents that teach AI Agents how to use the `lansenger` CLI. Each Skill covers a business domain (messaging, calendar, groups, etc.) with:

- **Core concepts** and terminology
- **CLI command reference** with parameters and examples
- **CRITICAL constraints** to prevent Agent mistakes
- **Common mistakes** table
- **Detailed reference docs** for complex operations

## Quick Install

### Method 1 — `npx skills` (Recommended)

The fastest way to install. Works with **OpenCode**, **Claude Code**, **Cursor**, **Codex**, **Cline**, and [50+ other agents](https://github.com/vercel-labs/skills#supported-agents).

```bash
# Install all Skills to all detected agents (interactive)
npx skills add lansenger-pm/lansenger-skills-official

# Install to a specific agent (e.g. opencode)
npx skills add lansenger-pm/lansenger-skills-official -a opencode

# Install to Claude Code globally
npx skills add lansenger-pm/lansenger-skills-official -a claude-code -g

# Install to multiple agents
npx skills add lansenger-pm/lansenger-skills-official -a opencode -a claude-code -a cursor

# Install only specific Skills
npx skills add lansenger-pm/lansenger-skills-official --skill lansenger-messaging --skill lansenger-calendar

# List available Skills before installing
npx skills add lansenger-pm/lansenger-skills-official --list

# Non-interactive / CI-friendly
npx skills add lansenger-pm/lansenger-skills-official --all -y
```

### Method 2 — opencode `.opencode/skills/`

For **opencode** users, copy or symlink the `skills/` directory:

```bash
# Symlink (recommended — single source of truth, easy to update)
ln -s $(pwd)/skills ~/.config/opencode/skills/lansenger-skills-official

# Or copy
cp -r skills ~/.config/opencode/skills/lansenger-skills-official
```

### Method 3 — Claude Code `.claude/skills/`

```bash
# Symlink into Claude Code's skills directory
ln -s $(pwd)/skills .claude/skills/lansenger-skills-official

# Global install
ln -s $(pwd)/skills ~/.claude/skills/lansenger-skills-official
```

### Method 4 — Manual (Any Agent)

Clone this repo and point your Agent to the `skills/` directory:

```bash
git clone https://github.com/lansenger-pm/lansenger-skills-official.git
# Then instruct your Agent to read skill_manifest.json first,
# then the relevant SKILL.md files based on user needs.
```

### Method 5 — `.agents/skills/` (Universal path)

Many agents (Amp, Cline, Codex, Cursor, Gemini CLI, etc.) share `.agents/skills/` as a standard path:

```bash
ln -s $(pwd)/skills .agents/skills/lansenger-skills-official
```

## Updating Skills

```bash
# If installed via npx skills
npx skills update lansenger-skills-official

# If symlinked — just git pull
cd lansenger-skills-official && git pull
```

## Structure

```
skills/
  lansenger-shared/SKILL.md              # Shared rules (auth, config, security, errors)
  lansenger-messaging/SKILL.md           # Messaging strategy + references/
  lansenger-chat/SKILL.md               # Chat reading APIs
  lansenger-group/SKILL.md              # Group management
  lansenger-staff/SKILL.md              # Contacts & staff
  lansenger-department/SKILL.md         # Department hierarchy
  lansenger-calendar/SKILL.md           # Calendar & schedules + references/
  lansenger-todo/SKILL.md               # Unified todo
  lansenger-oauth/SKILL.md              # OAuth2 user auth
  lansenger-streaming/SKILL.md          # Streaming messages (AI-Agent SSE)
  lansenger-callback/SKILL.md           # Callback events & webhook
  lansenger-media/SKILL.md              # Media file upload/download
skill_manifest.json                      # Index of all skills
skill-template/                          # Templates for creating new skills
```

## Skills Index

| Skill | Description |
|-------|-------------|
| `lansenger-shared` | Auth, config, error handling, security rules (auto-loaded by all others) |
| `lansenger-messaging` | 4 messaging channels, message type matrix, @mention rules, reminder, CLI method selection |
| `lansenger-chat` | Fetch chat list (private + group) and pull messages from conversations |
| `lansenger-group` | Create groups, fetch info/members, list groups, check membership, update settings, dismiss groups |
| `lansenger-staff` | Fetch staff info, ID mapping (phone/email→staffId), org extra fields, search |
| `lansenger-department` | Navigate org hierarchy, fetch department detail/children, list department staff |
| `lansenger-calendar` | Primary calendar, schedule CRUD, attendee management, attendee metadata |
| `lansenger-todo` | Create, update, query, delete todo tasks, manage executors, status counts |
| `lansenger-oauth` | OAuth2 user auth flow, authorize URL, code exchange, token refresh |
| `lansenger-streaming` | SSE-based real-time message delivery for AI agents |
| `lansenger-callback` | 25 event types, structured parsing, AES decryption, signature verification |
| `lansenger-media` | Upload/download files, images, videos, audio, get media path |

## CLI Compatibility

These Skills work with both the Python CLI and Go CLI:

```bash
# Python CLI
pip install lansenger-cli
lansenger message send-text staff123 "Hello"

# Go CLI
go install github.com/lansenger-pm/lansenger-sdk-go/cmd/lansenger@latest
lansenger message send-text staff123 "Hello"
```

Both CLIs share the same command structure, parameter names, and output formats, so one set of Skills serves both.

## Multi-App / Multi-Bot Configuration

The CLI supports multiple profiles (each corresponding to an appID). See `lansenger-shared/SKILL.md` for details:

```bash
# Configure multiple apps by profile name
lansenger config set --profile "my-personal-bot"
lansenger config set --profile "my-lansenger-app"

# Switch identity via --profile
lansenger message send-text staff123 "Hello" --profile "my-personal-bot"
lansenger calendar primary --profile "my-lansenger-app" --user-token "ut1"
```

## Contributing

See the `skill-template/` directory for templates when creating new Skills.

## License

MIT