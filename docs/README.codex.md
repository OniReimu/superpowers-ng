# Superpowers for Codex

Guide for using Superpowers with OpenAI Codex via native skill discovery.

## Quick Install

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/OniReimu/superpowers-ng/refs/heads/main/.codex/INSTALL.md
```

## Manual Installation

### Prerequisites

- OpenAI Codex CLI
- Git

### Steps

1. Clone the repo:
   ```bash
   git clone https://github.com/OniReimu/superpowers-ng.git ~/.codex/superpowers
   ```

2. Create the skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
   ```

3. Restart Codex.

### Windows

Use a junction instead of a symlink (works without Developer Mode):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\superpowers" "$env:USERPROFILE\.codex\superpowers\skills"
```

## How It Works

Codex has native skill discovery — it scans `~/.agents/skills/` at startup, parses SKILL.md frontmatter, and loads skills on demand. Superpowers skills are made visible through a single symlink:

```
~/.agents/skills/superpowers/ → ~/.codex/superpowers/skills/
```

The `using-superpowers` skill is discovered automatically and enforces skill usage discipline — no additional configuration needed.

## Usage

Skills are discovered automatically. Codex activates them when:
- You mention a skill by name (e.g., "use brainstorming")
- The task matches a skill's description
- The `using-superpowers` skill directs Codex to use one

### Project Skills

Create project-specific skills in `.codex/skills/` within your project root:

```bash
mkdir -p .codex/skills/my-project-skill
```

Create `.codex/skills/my-project-skill/SKILL.md`:

```markdown
---
name: my-project-skill
description: Use when [condition] - [what it does]
---

# My Project Skill

[Your skill content here]
```

Project skills have the highest priority and override both personal and superpowers skills with the same name.

### Personal Skills

Create your own skills in `~/.agents/skills/`:

```bash
mkdir -p ~/.agents/skills/my-skill
```

Create `~/.agents/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

The `description` field is how Codex decides when to activate a skill automatically — write it as a clear trigger condition.

### Skill Priority

Skills are resolved with three-tier priority:

1. **Project skills** (`.codex/skills/` in project root) - Highest priority
2. **Personal skills** (`~/.agents/skills/`)
3. **Superpowers skills** (`~/.agents/skills/superpowers/`) - via symlink

### Tool Mapping

Skills written for Claude Code are adapted for Codex with these mappings:

- `TodoWrite` → `update_plan`
- `Task` with subagents → `spawn_agent` + `wait` (or sequential if collab disabled)
- `Skill` tool → native `$skill-name` mention
- `Read`, `Write`, `Edit`, `Bash` → use native Codex equivalents

## Manus Planning on Codex

The `manus-planning` skill works on Codex with these considerations:

- The 3-file system (`task_plan.md`, `findings.md`, `progress.md`) works identically
- PreToolUse hooks via `docs/manus/.active` marker operate the same way
- Use native file operations instead of Claude Code-specific tools
- The archive system (`docs/manus/archive/`) is fully compatible
- The 2-Action Rule (update `findings.md` after every 2 search/view operations) applies

### Getting Started with Manus on Codex

1. Ask Codex to "use manus-planning" or describe a complex task
2. The skill creates the 3 files in `docs/manus/`
3. The `.active` marker enables PreToolUse hook reminders
4. Work persists across context resets and sessions

## Ralph Integration on Codex

When using Superpowers-NG with [Ralph](https://github.com/frankbria/ralph-claude-code):

- Brainstorming Phase 0 (existing design detection) works natively
- Manus planning files persist across Ralph loop resets
- Skills are autonomous-mode aware — no user input needed in Ralph loops
- Auto-resume via `.active` marker detection works with Ralph's `--continue` model

## Updating

```bash
cd ~/.codex/superpowers && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/superpowers
```

**Windows (PowerShell):**
```powershell
Remove-Item "$env:USERPROFILE\.agents\skills\superpowers"
```

Optionally delete the clone: `rm -rf ~/.codex/superpowers` (Windows: `Remove-Item -Recurse -Force "$env:USERPROFILE\.codex\superpowers"`).

## Troubleshooting

### Skills not showing up

1. Verify the symlink: `ls -la ~/.agents/skills/superpowers`
2. Check skills exist: `ls ~/.codex/superpowers/skills`
3. Restart Codex — skills are discovered at startup

### Windows junction issues

Junctions normally work without special permissions. If creation fails, try running PowerShell as administrator.

## Getting Help

- Report issues: https://github.com/OniReimu/superpowers-ng/issues
- Main documentation: https://github.com/OniReimu/superpowers-ng
