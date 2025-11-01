Pickleball/FlowEntry.md
# Pickleball — Flow State Entry Conditions

This doc defines *exact* triggers, checks, and rituals to enter Flow State under Captain’s Protocol.

---

## 1) Preconditions (Green Lights Only)
- **Objective**: One clear, testable target (≤ 2 sentences).
- **Anchor file** open: `ExcaliburFlowState.md` (Section to update named).
- **Env clean**: tests pass or failing tests are intentional + listed.
- **Distractions**: notifications off, single workspace, music set (optional).

---

## 2) 60-Second Entry Ritual
1. Read the objective aloud (quietly).  
2. Update **Now Box** in `ExcaliburFlowState.md`:
   - `Now: <task> | Definition of Done: <assertion/test> | Timebox: 25m`
3. Start timer: 25 minutes.
4. Run **warm start**:
   - `git status` (no surprises)  
   - `pytest -q` (or fast subset)  
5. Commit checkpoint (optional): `chore: enter flow — <task>`

---

## 3) Command Palette (Flow Primitives)
- **Start**: `xf start "<task>" --d=<done-assertion> --t=25m`
- **Checkpoint**: `xf mark "notable change"`
- **Test**: `xf test` → `PYTHONPATH=. pytest -q`
- **Note**: `xf note "<insight>"` → appends to `ExcaliburFlowState.md#Scratch`
- **Focus**: `xf focus 15m` → micro-sprint
- **Park**: `xf park "<open loop>"` → logs parking lot + clears attention
- **Stop**: `xf stop` → writes summary & prompts commit

> (Implement `xf` later; use the exact semantics above when we scaffold the CLI.)

---

## 4) First Minute of Work (Micro-Plan)
- Identify **smallest slice** that proves progress (Δ ≤ 20 lines or one test).
- Write/adjust **one test** that fails meaningfully.
- Make it pass with **minimal code**.
- Refactor if obvious (≤ 5 min), else `xf park "refactor X later"`.

---

## 5) Guardrails (Stay in Flow)
- No tab spam: max 5 tabs/panes.
- No web until **two local attempts** fail; then **time-box 7 minutes**.
- No premature optimization; pass test first.
- If you type “hmm…” twice → create a **Scratch** note, not a detour.

---

## 6) Recovery Protocol (Flow Break Fix)
- If interrupted > 2 minutes:  
  1) `xf stop` (snapshot)  
  2) Read **Now Box**  
  3) Re-run tests  
  4) Resume or `xf start "<restated task>"`

- If stuck > 10 minutes:  
  - Write **Rubber-Duck Blocker** in Scratch: *“I expect X, I see Y, I tried A/B.”*  
  - Decide: **Split task** or **Ask Anima** with that exact block.

---

## 7) Exit Conditions (Close the Loop)
- Definition of Done satisfied (test/assert passes).
- Commit + message: `feat/fix: <concise outcome>`
- Update **ExcaliburFlowState.md**:  
  - `Now → Done: <what changed>`  
  - `Next: <single next target or empty>`  
- Optional: short retrospective (≤ 3 bullets).

---

## 8) Templates

### 8.1 Now Box
Now: <task>  
Definition of Done: <assertion/test/outcome>  
Timebox: <25m|15m>  

### 8.2 Commit Messages
feat: <user-visible value>  
fix: <bug + reproduction>  
chore: enter/exit flow — <task>  
refactor: <scope>  
test: <what behavior is covered>  

### 8.3 Scratch (in ExcaliburFlowState.md)
- Insight:  
- Blocker (I expect X / I see Y / I tried A, B):  
- Parking Lot:  

---

## 9) Tooling Note
The minimal tooling (`xf` CLI) has been scaffolded in `bin/xf`.

See that script for:
- Flow start ritual
- Now Box capture
- Notes, parking lot, marks
- Basic test runner

This replaces the earlier “TODO” list.

---