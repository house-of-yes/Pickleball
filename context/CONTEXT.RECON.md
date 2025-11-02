# Context Reconstitution (Pickleball)

**Why this exists.**  
Pickleball is not just code; it’s culture and control. We previously kept rules
(dyads, path inference, RP-ready behavior, alias lexicon) in volatile memory.
This document anchors that context in the repo so it travels with the work.

## What belongs under `context/`
- `riot.act` — standing operational rules (RP-ready file rule, serve/append path inference, etc.)
- `DYADS.yaml` — the command lexicon and behaviors (authoritative)
- `CONTEXT.RECON.md` — this explainer and pointers
- `Mappings/` *(optional)* — canonical nicknames → paths (e.g., “wallet enrichment script” → canonical file)
- `History/` *(optional)* — dated snapshots of rules for auditability

## Relationship to Pickleball
Pickleball’s loop (serve → rally → call → point → reset) depends on *clear calls* and *fast resets*.
That only works when conversational control is explicit. The dyads and riot.act are the controls that
make rhythm reliable. Therefore, **context is part of Pickleball’s codebase**.

## Ground Rules
1. **Repo is canonical.** If it’s not in `/context`, it isn’t a standing rule.
2. **Small, explicit edits.** Treat changes to DYADS or riot.act as serves; PRs should be tiny.
3. **Traceability.** When a dyad changes behavior, note the change and rationale in PR text.
4. **No ghost features.** Don’t rely on “assistant memory” for controls; mirror them here.
5. **Multilingual by default.** Command semantics must survive translation.

## Implementation Notes
- **File format:** `DYADS.yaml` is machine-readable and diff-friendly.
- **Activation logic:** Two-word rule + multilingual aliasing are first-class.
- **Suggestion discipline:** Off by default unless explicitly enabled.

## Maintenance
- Owners: *Anima & Clem* (HOY POLLOI 1.0)
- Version bump `DYADS.yaml` when adding/removing dyads or rules.
- Keep `riot.act` and `DYADS.yaml` consistent (no conflicting directives).

## Next Serves
- Migrate any nickname→path mappings you rely on into `context/mappings.yaml`.
- Bring over the latest `riot.act` so the RP-ready rule is in-repo (if not already).
- Add test snippets/examples under `examples/` to demonstrate dyad effects in practice.
