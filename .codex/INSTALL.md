# Installing Superpowers for Codex

Enable superpowers skills in Codex via native skill discovery. Clone, symlink, and bootstrap.

## Prerequisites

- Git

## Choose Your Installation Scope

| | Global | Project-Local |
|---|---|---|
| **Skills available in** | All projects on your machine | One specific repository |
| **Best for** | Personal use across all projects | Teams sharing superpowers via the repo, or per-project version control |
| **Clone location** | `~/.codex/superpowers-ng` | Inside the project (submodule or gitignored clone) |
| **Symlink location** | `~/.agents/skills/superpowers-ng` | `<project-root>/.agents/skills/superpowers-ng` |
| **Bootstrap location** | `~/.codex/AGENTS.md` | `<project-root>/.codex/AGENTS.md` |
| **Codex scope** | User | Repo (highest priority) |

---

## Global Installation

Installs superpowers-ng for all projects on your machine.

1. **Clone the superpowers repository:**
   ```bash
   git clone https://github.com/OniReimu/superpowers-ng.git ~/.codex/superpowers-ng
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/superpowers-ng/skills ~/.agents/skills/superpowers-ng
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\superpowers-ng" "$env:USERPROFILE\.codex\superpowers-ng\skills"
   ```

3. **Bootstrap the `using-superpowers` skill:**

   The symlink makes skills discoverable, but Codex won't auto-invoke them at conversation start. Add a bootstrap instruction to `AGENTS.md` so the agent always loads the skill system first:

   ```bash
   cat >> ~/.codex/AGENTS.md << 'EOF'

   <!-- superpowers-ng bootstrap -->
   At the start of every conversation, before any response (including clarifying questions), invoke the `superpowers-ng:using-superpowers` skill.
   <!-- /superpowers-ng bootstrap -->
   EOF
   ```

   > **Why?** Codex does not support hooks. In Claude Code, a `SessionStart` hook auto-injects this skill. In Codex, `AGENTS.md` is the only way to achieve the same effect.

4. **Restart Codex** (quit and relaunch the CLI) to discover the skills.

### Verify (Global)

```bash
ls -la ~/.agents/skills/superpowers-ng
```

You should see a symlink pointing to `~/.codex/superpowers-ng/skills/`.

Verify the bootstrap is in place:

```bash
grep -q 'superpowers-ng bootstrap' ~/.codex/AGENTS.md && echo "Bootstrap OK" || echo "Bootstrap missing"
```

### Update (Global)

```bash
cd ~/.codex/superpowers-ng && git pull
```

### Uninstall (Global)

```bash
rm ~/.agents/skills/superpowers-ng
rm -rf ~/.codex/superpowers-ng
```

Remove the `<!-- superpowers-ng bootstrap -->` block from `~/.codex/AGENTS.md`.

---

## Project-Local Installation

Installs superpowers-ng scoped to a single repository. Codex discovers these skills at Repo scope (highest priority).

### Option A: Git Submodule (recommended for teams)

Version-pinned and committed to the repo. All collaborators get the same superpowers version.

1. **Add superpowers-ng as a submodule:**
   ```bash
   git submodule add https://github.com/OniReimu/superpowers-ng.git .codex/superpowers-ng
   ```

2. **Create the project-local skills symlink:**
   ```bash
   mkdir -p .agents/skills
   ln -s ../../.codex/superpowers-ng/skills .agents/skills/superpowers-ng
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path ".agents\skills"
   cmd /c mklink /J ".agents\skills\superpowers-ng" ".codex\superpowers-ng\skills"
   ```

3. **Bootstrap the `using-superpowers` skill:**

   ```bash
   cat >> .codex/AGENTS.md << 'EOF'

   <!-- superpowers-ng bootstrap -->
   At the start of every conversation, before any response (including clarifying questions), invoke the `superpowers-ng:using-superpowers` skill.
   <!-- /superpowers-ng bootstrap -->
   EOF
   ```

4. **Commit the submodule, symlink, and bootstrap:**
   ```bash
   git add .gitmodules .codex/superpowers-ng .agents/skills/superpowers-ng .codex/AGENTS.md
   git commit -m "Add superpowers-ng as project-local skill suite"
   ```

5. **Restart Codex.**

> **For collaborators cloning the repo:** Run `git submodule update --init` to fetch the superpowers-ng submodule, then create the symlink (step 2). The bootstrap in `.codex/AGENTS.md` is already committed.

### Option B: Local Clone (solo use)

Not committed to the repo. Good for trying superpowers-ng in a single project without affecting the repo.

1. **Clone into the project:**
   ```bash
   git clone https://github.com/OniReimu/superpowers-ng.git .codex/superpowers-ng
   ```

2. **Create the project-local skills symlink:**
   ```bash
   mkdir -p .agents/skills
   ln -s ../../.codex/superpowers-ng/skills .agents/skills/superpowers-ng
   ```

3. **Bootstrap the `using-superpowers` skill:**

   ```bash
   cat >> .codex/AGENTS.md << 'EOF'

   <!-- superpowers-ng bootstrap -->
   At the start of every conversation, before any response (including clarifying questions), invoke the `superpowers-ng:using-superpowers` skill.
   <!-- /superpowers-ng bootstrap -->
   EOF
   ```

4. **Add to `.gitignore`:**
   ```bash
   echo ".codex/superpowers-ng" >> .gitignore
   echo ".agents/" >> .gitignore
   ```

5. **Restart Codex.**

### Verify (Project-Local)

From the project root:

```bash
ls -la .agents/skills/superpowers-ng
```

You should see a symlink pointing to `../../.codex/superpowers-ng/skills`.

Verify the bootstrap is in place:

```bash
grep -q 'superpowers-ng bootstrap' .codex/AGENTS.md && echo "Bootstrap OK" || echo "Bootstrap missing"
```

### Update (Project-Local)

**Submodule:**
```bash
cd .codex/superpowers-ng && git pull origin main
cd ../.. && git add .codex/superpowers-ng && git commit -m "Update superpowers-ng"
```

**Local clone:**
```bash
cd .codex/superpowers-ng && git pull
```

### Uninstall (Project-Local)

**Submodule:**
```bash
git submodule deinit .codex/superpowers-ng
git rm .codex/superpowers-ng
rm .agents/skills/superpowers-ng
```

Remove the `<!-- superpowers-ng bootstrap -->` block from `.codex/AGENTS.md`, then:

```bash
git add .codex/AGENTS.md
git commit -m "Remove superpowers-ng"
```

**Local clone:**
```bash
rm .agents/skills/superpowers-ng
rm -rf .codex/superpowers-ng
```

Remove the `<!-- superpowers-ng bootstrap -->` block from `.codex/AGENTS.md`.

---

## Migrating from old bootstrap

If you installed superpowers before native skill discovery, you need to:

1. **Update the repo:**
   ```bash
   cd ~/.codex/superpowers-ng && git pull
   ```

2. **Create the skills symlink** (see Global Installation step 2) — this is the new discovery mechanism.

3. **Replace the old bootstrap block** in `~/.codex/AGENTS.md`:
   - Remove any block referencing `superpowers-codex bootstrap` (the old mechanism).
   - Add the new bootstrap (see Global Installation step 3).

4. **Restart Codex.**
