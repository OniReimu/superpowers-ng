# Superpowers for Codex

Guide for using Superpowers with OpenAI Codex via native skill discovery.

## Quick Install

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/OniReimu/superpowers-ng/refs/heads/main/.codex/INSTALL.md
```

The install guide covers both global and project-local installation. See [.codex/INSTALL.md](../.codex/INSTALL.md) for the full instructions.

## Manual Installation

### Prerequisites

- OpenAI Codex CLI
- Git

### Global (all projects)

1. Clone the repo:
   ```bash
   git clone https://github.com/OniReimu/superpowers-ng.git ~/.codex/superpowers-ng
   ```

2. Create the skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/superpowers-ng/skills ~/.agents/skills/superpowers-ng
   ```

3. Restart Codex.

### Project-Local (single repo)

1. Add as a submodule (or clone into `.codex/superpowers-ng`):
   ```bash
   git submodule add https://github.com/OniReimu/superpowers-ng.git .codex/superpowers-ng
   ```

2. Create the project-local skills symlink:
   ```bash
   mkdir -p .agents/skills
   ln -s ../../.codex/superpowers-ng/skills .agents/skills/superpowers-ng
   ```

3. Restart Codex.

See [.codex/INSTALL.md](../.codex/INSTALL.md) for Windows instructions, local-clone option, and collaborator setup.

### Windows

Use a junction instead of a symlink (works without Developer Mode):

**Global:**
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\superpowers-ng" "$env:USERPROFILE\.codex\superpowers-ng\skills"
```

**Project-local:**
```powershell
New-Item -ItemType Directory -Force -Path ".agents\skills"
cmd /c mklink /J ".agents\skills\superpowers-ng" ".codex\superpowers-ng\skills"
```

## How It Works

Codex has native skill discovery — it scans for `SKILL.md` files in multiple locations at startup, parses YAML frontmatter, and loads skills on demand.

**Global installation** places superpowers skills in `~/.agents/skills/` (User scope):

```
~/.agents/skills/superpowers-ng/ → ~/.codex/superpowers-ng/skills/
```

**Project-local installation** places them in `.agents/skills/` at the repo root (Repo scope):

```
<project>/.agents/skills/superpowers-ng/ → ../../.codex/superpowers-ng/skills/
```

Repo scope has the highest priority — project-local superpowers override a global installation of the same skills. The `using-superpowers` skill is discovered automatically and enforces skill usage discipline — no additional configuration needed.

## Usage

Skills are discovered automatically. Codex activates them when:
- You mention a skill by name (e.g., "use brainstorming")
- The task matches a skill's description
- The `using-superpowers` skill directs Codex to use one

### Custom Project Skills

Create additional project-specific skills in `.codex/skills/` or `.agents/skills/` within your project root:

```bash
mkdir -p .agents/skills/my-project-skill
```

Create `.agents/skills/my-project-skill/SKILL.md`:

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

Skills are resolved with a hierarchical priority:

1. **Project skills** (`.agents/skills/` or `.codex/skills/` in project root) — Repo scope, highest priority
2. **Personal skills** (`~/.agents/skills/`) — User scope
3. **System skills** (`$CODEX_HOME/skills/.system`) — bundled by OpenAI
4. **Admin skills** (`/etc/codex/skills/`) — lowest priority

When superpowers-ng is installed globally, its skills live at tier 2 (User). When installed project-locally, they move to tier 1 (Repo) and take highest priority.

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

**Global:**
```bash
cd ~/.codex/superpowers-ng && git pull
```

**Project-local (submodule):**
```bash
cd .codex/superpowers-ng && git pull origin main
cd ../.. && git add .codex/superpowers-ng && git commit -m "Update superpowers-ng"
```

**Project-local (clone):**
```bash
cd .codex/superpowers-ng && git pull
```

Skills update instantly through the symlink.

## Uninstalling

**Global:**
```bash
rm ~/.agents/skills/superpowers-ng
rm -rf ~/.codex/superpowers-ng
```

**Project-local (submodule):**
```bash
git submodule deinit .codex/superpowers-ng
git rm .codex/superpowers-ng
rm .agents/skills/superpowers-ng
git commit -m "Remove superpowers-ng"
```

**Project-local (clone):**
```bash
rm .agents/skills/superpowers-ng
rm -rf .codex/superpowers-ng
```

**Windows (PowerShell):**
```powershell
Remove-Item "$env:USERPROFILE\.agents\skills\superpowers-ng"
```

## Troubleshooting

### Skills not showing up

1. Verify the symlink:
   - Global: `ls -la ~/.agents/skills/superpowers-ng`
   - Project-local: `ls -la .agents/skills/superpowers-ng`
2. Check skills exist: `ls` the symlink target directory
3. Restart Codex — skills are discovered at startup

### Windows junction issues

Junctions normally work without special permissions. If creation fails, try running PowerShell as administrator.

## Getting Help

- Report issues: https://github.com/OniReimu/superpowers-ng/issues
- Main documentation: https://github.com/OniReimu/superpowers-ng
