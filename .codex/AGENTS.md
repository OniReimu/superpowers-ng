# Superpowers-NG Codex Session Bootstrap

At the start of every conversation, before any task work:

1. Invoke `superpowers-ng:using-superpowers`.
2. Run `./hooks/planning-bootstrap.sh --mode codex`.
3. Follow the bootstrap result exactly.

Bootstrap policy:

- If output starts with `Planning mode: MANUS`:
  - Read `docs/manus/task_plan.md`, `docs/manus/progress.md`, `docs/manus/findings.md`.
  - Continue the existing task and keep appending to `progress.md` (and `findings.md` when relevant).
  - In the first response, include:
    - a one-line mode status line
    - a short continuation summary
    - the exact next step

- If output starts with `Planning mode: NATIVE`:
  - Start native planning flow with a lightweight 3-line plan:
    - `Goal: ...`
    - `Steps: ...`
    - `Verification: ...`
  - Ask whether to enable Manus: `Enable manus persistent planning for this task? (yes/no)`
  - In the first response, include a one-line mode status line.

Quick mode switches:

- enable manus:
  - `mkdir -p docs/manus`
  - `cp skills/manus-planning/templates/task_plan.md docs/manus/task_plan.md`
  - `cp skills/manus-planning/templates/findings.md docs/manus/findings.md`
  - `cp skills/manus-planning/templates/progress.md docs/manus/progress.md`
  - `touch docs/manus/.active`

- close task:
  - `stamp="$(date +%Y-%m-%d-%H%M%S)"; mkdir -p "docs/manus/archive/$stamp"`
  - `mv docs/manus/task_plan.md docs/manus/findings.md docs/manus/progress.md "docs/manus/archive/$stamp/" 2>/dev/null || true`
  - `rm -f docs/manus/.active`
