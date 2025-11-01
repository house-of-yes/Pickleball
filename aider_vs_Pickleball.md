# Aider vs Pickleball: Notes & Fit

This note compares **Aider** (an open-source terminal coding assistant) with **Pickleball** (our Termux/Android-first control plane and workflow). It also outlines how to use Aider alongside Pickleball without breaking our rituals (RP, clean, tests, commits).

---

## What is Aider?

Aider is a CLI tool that connects your local git repo to an LLM (Anthropic Claude, OpenAI GPT, etc.). You chat in the terminal, and it edits files directly, making commits with explanations.

- Homepage: https://aider.chat
- Repo: https://github.com/paul-gauthier/aider

---

## How Aider Works (in one glance)

1. Run `aider` inside a git repo.
2. Tell it what to change; optionally list files to focus on.
3. It proposes/patches edits and commits with messages summarizing changes.
4. You review `git diff` at any point and keep/revert as desired.

---

## Pros of Aider

- **Direct code edits:** No copy/paste gymnastics; edits are applied to files.
- **Commit trail:** Auto-commits with explanations → clear history and rollback.
- **Multi-file awareness:** Can coordinate changes across modules.
- **Open-source:** Inspect, extend, or self-host wrapper scripts.

## Cons of Aider

- **Requires an LLM key:** Claude/GPT needed; not fully local.
- **Privacy surface:** Code sent to provider you choose (respect org policies).
- **Workflow learning curve:** Needs a bit of muscle memory vs plain editor.
- **Not an IDE:** No rich UI; terminal-first experience.

---

## Pickleball vs Aider (roles)

- **Pickleball** = discipline & ritual  
  Termux-native harness that enforces our guardrails: RP-ready file drops, glyph scrubbing, `clean && test`, commit etiquette, and project-specific conventions.

- **Aider** = fast multi-file edits  
  Great when you need coordinated refactors or rapid iteration without manual patching. Commits changes directly with messages.

**Conclusion:** They’re complementary. Keep Pickleball as the control plane; use Aider as an editor/agent that proposes and applies code changes under Pickleball’s rules.

---

## Safe Coexistence Pattern

- Keep using Pickleball commands (`rp`, `clean`, `test`, etc.).
- Run Aider **inside** repos Pickleball manages.
- After Aider edits:
  - `clean && pytest -q`
  - If green, stage/commit per our conventions (or accept Aider’s auto-commit).
  - Run glyph scrubbers if needed before push.

---

## Minimal Aider Quickstart (reference)

> Keep credentials out of history; store API keys in your preferred secure method.

1. Install:
   - `pip install aider-chat` (or use a venv)
2. Set an LLM provider key (example Claude):
   - `export ANTHROPIC_API_KEY=...`
3. From repo root:
   - `aider`  
     (add `--model claude-3-5-sonnet-latest` or your preferred model)
4. Give it a focused request:
   - “Refactor `king_of_swing/bin/dashboard` into smaller modules; keep CLI stable.”

---

## Privacy & Trust

- **Providers**: Anthropic/OpenAI are established vendors with enterprise offerings; read their current data policies before sharing sensitive code.
- **Scope**: Limit the files you share (Aider supports specifying file lists).
- **Git diff**: Always review diffs before pushing.

---

## When to Prefer Pickleball Alone

- Strict RP-ready drop-ins, no multi-file edits.
- Low bandwidth conditions where patch churn must be minimal.
- When reproducible rituals (test gates, logs, glyph-scrub) are paramount.

## When Aider Shines

- Multi-file refactors and scaffolding.
- Applying consistent changes across modules/tests.
- Rapid iteration on internal APIs with auto-commits and diffs.

---

## Working Agreement (TL;DR)

- Pickleball remains the **control plane**.
- Aider is a **power tool** used *within* that plane.
- Every Aider change flows through: `clean → test → review diff → commit/push`.

---
