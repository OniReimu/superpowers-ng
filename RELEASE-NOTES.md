# Superpowers-NG Release Notes

## Upstream v4.3.0 (2026-02-12)

This fix should dramatically improve superpowers skills compliance and should reduce the chances of Claude entering its native plan mode unintentionally.

### Changed

**Brainstorming skill now enforces its workflow instead of describing it**

Models were skipping the design phase and jumping straight to implementation skills like frontend-design, or collapsing the entire brainstorming process into a single text block. The skill now uses hard gates, a mandatory checklist, and a graphviz process flow to enforce compliance:

- `<HARD-GATE>`: no implementation skills, code, or scaffolding until design is presented and user approves
- Explicit checklist (6 items) that must be created as tasks and completed in order
- Graphviz process flow with `writing-plans` as the only valid terminal state
- Anti-pattern callout for "this is too simple to need a design" — the exact rationalization models use to skip the process
- Design section sizing based on section complexity, not project complexity

**Using-superpowers workflow graph intercepts EnterPlanMode**

Added an `EnterPlanMode` intercept to the skill flow graph. When the model is about to enter Claude's native plan mode, it checks whether brainstorming has happened and routes through the brainstorming skill instead. Plan mode is never entered.

### Fixed

**SessionStart hook now runs synchronously**

Changed `async: true` to `async: false` in hooks.json. When async, the hook could fail to complete before the model's first turn, meaning using-superpowers instructions weren't in context for the first message.

## Upstream v4.2.0 (2026-02-05)

### Breaking Changes

**Codex: Replaced bootstrap CLI with native skill discovery**

The `superpowers-codex` bootstrap CLI, Windows `.cmd` wrapper, and related bootstrap content file have been removed. Codex now uses native skill discovery via `~/.agents/skills/superpowers/` symlink, so the old `use_skill`/`find_skills` CLI tools are no longer needed.

Installation is now just clone + symlink (documented in INSTALL.md). No Node.js dependency required. The old `~/.codex/skills/` path is deprecated.

### Fixes

**Windows: Fixed Claude Code 2.1.x hook execution (#331)**

Claude Code 2.1.x changed how hooks execute on Windows: it now auto-detects `.sh` files in commands and prepends `bash`. This broke the polyglot wrapper pattern because `bash "run-hook.cmd" session-start.sh` tries to execute the `.cmd` file as a bash script.

Fix: hooks.json now calls session-start.sh directly. Claude Code 2.1.x handles the bash invocation automatically. Also added .gitattributes to enforce LF line endings for shell scripts (fixes CRLF issues on Windows checkout).

**Windows: SessionStart hook runs async to prevent terminal freeze (#404, #413, #414, #419)**

The synchronous SessionStart hook blocked the TUI from entering raw mode on Windows, freezing all keyboard input. Running the hook async prevents the freeze while still injecting superpowers context.

**Windows: Fixed O(n^2) `escape_for_json` performance**

The character-by-character loop using `${input:$i:1}` was O(n^2) in bash due to substring copy overhead. On Windows Git Bash this took 60+ seconds. Replaced with bash parameter substitution (`${s//old/new}`) which runs each pattern as a single C-level pass — 7x faster on macOS, dramatically faster on Windows.

**Codex: Fixed Windows/PowerShell invocation (#285, #243)**

- Windows doesn't respect shebangs, so directly invoking the extensionless `superpowers-codex` script triggered an "Open with" dialog. All invocations now prefixed with `node`.
- Fixed `~/` path expansion on Windows — PowerShell doesn't expand `~` when passed as an argument to `node`. Changed to `$HOME` which expands correctly in both bash and PowerShell.

**Codex: Fixed path resolution in installer**

Used `fileURLToPath()` instead of manual URL pathname parsing to correctly handle paths with spaces and special characters on all platforms.

**Codex: Fixed stale skills path in writing-skills**

Updated `~/.codex/skills/` reference (deprecated) to `~/.agents/skills/` for native discovery.

### Improvements

**Worktree isolation now required before implementation**

Added `using-git-worktrees` as a required skill for both `subagent-driven-development` and `executing-plans`. Implementation workflows now explicitly require setting up an isolated worktree before starting work, preventing accidental work directly on main.

**Main branch protection softened to require explicit consent**

Instead of prohibiting main branch work entirely, the skills now allow it with explicit user consent. More flexible while still ensuring users are aware of the implications.

**Simplified installation verification**

Removed `/help` command check and specific slash command list from verification steps. Skills are primarily invoked by describing what you want to do, not by running specific commands.

**Codex: Clarified subagent tool mapping in bootstrap**

Improved documentation of how Codex tools map to Claude Code equivalents for subagent workflows.

### Tests

- Added worktree requirement test for subagent-driven-development
- Added main branch red flag warning test
- Fixed case sensitivity in skill recognition test assertions

---

## Upstream v4.1.1 (2026-01-23)

### Fixes

**OpenCode: Standardized on `plugins/` directory per official docs (#343)**

OpenCode's official documentation uses `~/.config/opencode/plugins/` (plural). Our docs previously used `plugin/` (singular). While OpenCode accepts both forms, we've standardized on the official convention to avoid confusion.

Changes:
- Renamed `.opencode/plugin/` to `.opencode/plugins/` in repo structure
- Updated all installation docs (INSTALL.md, README.opencode.md) across all platforms
- Updated test scripts to match

**OpenCode: Fixed symlink instructions (#339, #342)**

- Added explicit `rm` before `ln -s` (fixes "file already exists" errors on reinstall)
- Added missing skills symlink step that was absent from INSTALL.md
- Updated from deprecated `use_skill`/`find_skills` to native `skill` tool references

---

## Upstream v4.1.0 (2026-01-23)

### Breaking Changes

**OpenCode: Switched to native skills system**

Superpowers for OpenCode now uses OpenCode's native `skill` tool instead of custom `use_skill`/`find_skills` tools. This is a cleaner integration that works with OpenCode's built-in skill discovery.

**Migration required:** Skills must be symlinked to `~/.config/opencode/skills/superpowers/` (see updated installation docs).

### Fixes

**OpenCode: Fixed agent reset on session start (#226)**

The previous bootstrap injection method using `session.prompt({ noReply: true })` caused OpenCode to reset the selected agent to "build" on first message. Now uses `experimental.chat.system.transform` hook which modifies the system prompt directly without side effects.

**OpenCode: Fixed Windows installation (#232)**

- Removed dependency on `skills-core.js` (eliminates broken relative imports when file is copied instead of symlinked)
- Added comprehensive Windows installation docs for cmd.exe, PowerShell, and Git Bash
- Documented proper symlink vs junction usage for each platform

**Claude Code: Fixed Windows hook execution for Claude Code 2.1.x**

Claude Code 2.1.x changed how hooks execute on Windows: it now auto-detects `.sh` files in commands and prepends `bash `. This broke the polyglot wrapper pattern because `bash "run-hook.cmd" session-start.sh` tries to execute the .cmd file as a bash script.

Fix: hooks.json now calls session-start.sh directly. Claude Code 2.1.x handles the bash invocation automatically. Also added .gitattributes to enforce LF line endings for shell scripts (fixes CRLF issues on Windows checkout).

---

## v0.1.0 (2026-01-13)

**Initial release** of Superpowers-NG, an enhanced fork of [obra/superpowers](https://github.com/obra/superpowers) with Manus-style persistent planning and Ralph integration.

### New Features

#### Manus Planning System

**File-based planning that survives context resets**

Added `manus-planning` skill inspired by [planning-with-files](https://github.com/OthmanAdi/planning-with-files) by OthmanAdi. This enables long-running tasks that span multiple sessions or exceed 50 tool calls.

**The 3 Files** (`docs/manus/`):
- `task_plan.md` - Goal, 5 phases (Requirements → Planning → Implementation → Testing → Delivery), decisions table, errors log
- `findings.md` - Requirements, research, technical decisions, resources (critical for visual/browser content that doesn't persist in context)
- `progress.md` - Session log with timestamps, test results table, error log, 5-question reboot check for context resumption

**Key Features:**
- **Persistent memory**: Files survive context resets, enabling work across multiple sessions
- **Automatic reminders**: PreToolUse hooks show plan preview before Write/Edit/Bash operations (when `.active` marker exists)
- **2-Action Rule**: After every 2 view/browser/search operations, update `findings.md` to preserve discoveries
- **Archive system**: Completed tasks auto-archive to `docs/manus/archive/YYYY-MM-DD-<topic>/`, new tasks get prompted (continue or start new)
- **5 Phases**: Structured workflow from Requirements through Delivery with status tracking

**Files:**
- `skills/manus-planning/SKILL.md` - Main skill definition
- `skills/manus-planning/templates/task_plan.md` - Phase tracking template
- `skills/manus-planning/templates/findings.md` - Research storage template
- `skills/manus-planning/templates/progress.md` - Session log template
- `commands/manus-plan.md` - Slash command `/manus-plan`
- `hooks/manus-pretool.sh` - Conditional PreToolUse hook (only active when marker file exists)

#### Brainstorming Enhancement

**Planning choice after design**

Updated `brainstorming` skill to present both planning options after design completion:
1. **Native planning** (writing-plans → executing-plans): Short tasks, interactive development
2. **Manus planning** (manus-planning): Long runs, multi-session projects

When Manus is chosen, design document content is automatically copied into `findings.md` for persistent reference.

**File:**
- `skills/brainstorming/SKILL.md` - Updated "After the Design" section

#### Planning Guidance

**Added planning approach comparison**

Updated `using-superpowers` skill with "Planning Approaches" section explaining when to use Native vs Manus planning:

| Approach | Skills | Best For |
|----------|--------|----------|
| **Native** | writing-plans + executing-plans | Short tasks (<30 min), interactive development with human checkpoints |
| **Manus** | manus-planning | Long autonomous runs, multi-session projects, tasks requiring >50 tool calls |

**File:**
- `skills/using-superpowers/SKILL.md` - Added planning guidance section

#### Ralph Integration

**Seamless integration with Ralph autonomous loop framework**

Added comprehensive support for using Superpowers-NG skills within [Ralph](https://github.com/frankbria/ralph-claude-code), the autonomous loop framework for Claude Code.

**Key improvements**:
- **brainstorming** now checks for existing design files before starting
  - Auto-detects `docs/plans/*-design.md`, `design.md`, or `docs/manus/findings.md`
  - In autonomous mode (Ralph loops): automatically uses existing design and skips to implementation
  - In interactive mode: offers choices (use existing, refine, start fresh)
  - Prevents redundant brainstorming in subsequent Ralph loops
- **manus-planning** already compatible with Ralph's multi-session nature
  - Persistent files survive loop resets
  - Auto-resumes via `.active` marker detection
  - Perfect for Ralph's `--continue` session model
- Phased brainstorming structure (Phase 0 → Phase 3) for clearer flow

**Documentation**:
- `docs/ralph-integration/README.md` - Complete integration guide
  - Architecture overview (Ralph vs Superpowers layers)
  - Skill lifecycle in Ralph loops (once per task vs every loop)
  - PROMPT.md structure and patterns
  - File management strategy
  - Common issues and solutions
- `docs/ralph-integration/PROMPT.template.md` - Ready-to-use PROMPT.md template
  - **Ralph's official status block format** with all required fields:
    - STATUS, TASKS_COMPLETED_THIS_LOOP, FILES_MODIFIED, TESTS_STATUS, WORK_TYPE, EXIT_SIGNAL, RECOMMENDATION
  - **Concrete examples**: 5 detailed scenarios showing exact status emissions
  - **Circuit breaker patterns**: Test-only loops, recurring errors, zero progress detection
  - **Anti-patterns table**: 8 explicitly forbidden patterns (refactor working code, add unplanned features, etc.)
  - **Exit criteria checklist**: 7-item checklist for when to set EXIT_SIGNAL: true
  - Conditional skill invocation (check for existing artifacts)
  - Autonomous mode behavior guidelines
  - Phase-based workflow with Superpowers skills
  - Customizable project context sections

**Updated Files**:
- `skills/brainstorming/SKILL.md` - Added Phase 0 (Check for Existing Design) with autonomous mode logic
- `README.md` - Added "Integration with Ralph" section

**Benefits for Ralph users**:
- No duplicate work across loops (design once, implement across many loops)
- Persistent memory via manus-planning files
- TDD and debugging discipline maintained across sessions
- Evidence-based completion signals (verification-before-completion)
- Ready-to-use templates for quick setup

### Technical Implementation

#### Hooks System Enhancement

**Conditional PreToolUse hook**

Added PreToolUse hook to `hooks.json` that fires before Write/Edit/Bash operations:
- Only outputs when `docs/manus/.active` marker file exists
- Displays first 30 lines of `task_plan.md` as context reminder
- Outputs empty JSON `{}` when inactive (no interference with native planning)
- Cross-platform compatible (uses same `run-hook.cmd` wrapper as SessionStart)

**Files:**
- `hooks/hooks.json` - Added PreToolUse matcher for Write|Edit|Bash
- `hooks/manus-pretool.sh` - Bash script with JSON escaping, checks marker file

### Breaking Changes

**Plugin renamed to superpowers-ng**

This fork is distributed separately from original superpowers:
- Plugin name: `superpowers-ng`
- Repository: `OniReimu/superpowers`
- Version reset to v0.1.0

**File:**
- `.claude-plugin/plugin.json` - Updated name, version, author, repository, added credits

### Credits

**Original Authors:**
- **Jesse Vincent (obra)** - [obra/superpowers](https://github.com/obra/superpowers) - Original Superpowers framework
- **Ahmad Othman Ammar Adi (OthmanAdi)** - [planning-with-files](https://github.com/OthmanAdi/planning-with-files) - Manus 3-file pattern

**Superpowers-NG:**
- **OniReimu** - Integration and enhancement

**Inspiration:**
- Manus AI (acquired by Meta for $2B) - Context engineering principles codified in planning-with-files

### Design Decisions

**Separate planning systems (no cross-style switching)**
- Native and Manus use different file formats and hooks
- Users choose one at the start based on task complexity
- Prevents format conflicts and unexpected behavior

**Marker file for conditional hooks**
- `.active` file enables/disables PreToolUse hooks
- Clean isolation: hooks don't fire for native planning
- Automatically removed on task completion

**Archive approach for multi-task handling**
- Completed tasks (no `.active`): Auto-archive to `docs/manus/archive/YYYY-MM-DD-<topic>/`
- In-progress tasks (`.active` exists): Prompt user to continue or start new
- Preserves history while keeping active location predictable

**Design document integration**
- Brainstorming → Manus flow copies design content into `findings.md`
- Becomes part of persistent research storage
- Accessible across context resets

### Known Limitations

**Installation requires manual setup**
- Marketplace integration pending
- Users must clone repository directly
- Will be resolved in future release

**No cross-platform testing**
- Hook script tested on macOS only
- Should work on Linux/Windows (uses polyglot wrapper)
- Community testing needed

### Upgrade Path

**For users of obra/superpowers:**
- Superpowers-NG is a separate fork, not a drop-in replacement
- Can install both plugins side-by-side
- Native planning workflows unchanged
- Manus planning is additive, opt-in feature

**For new users:**
- Start with either Native or Manus planning based on task
- Both workflows fully supported
- Brainstorming skill guides choice after design

### What's Next

**Planned enhancements:**
- Marketplace publication for easy installation
- Subagent handoff support (Task 8 from implementation plan)
- Template customization
- Cross-platform testing and validation
- Community feedback integration

---

**Full Changelog:** https://github.com/OniReimu/superpowers-ng/compare/obra:main...OniReimu:main
**Issues:** https://github.com/OniReimu/superpowers-ng/issues
**Original Superpowers:** https://github.com/obra/superpowers
**Planning-with-files:** https://github.com/OthmanAdi/planning-with-files
