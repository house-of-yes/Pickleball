Got it. Here’s a draft you can drop into the Cyborg’s Guide under a “Debugging Pickleball Failures” section. I’ve framed it so it feels like part of the existing mythos (Captain + Anima merged as the Cyborg), while also being practical step-by-step for future troubleshooting.


---

Debugging Pickleball Failures

When Pickleball falters, the Cyborg must step into its role as both warrior and mechanic.
This guide exists so that no failure stalls the flow for long. The principle is always: inspect before you invent, verify before you assume.


---

1. Recognizing Symptoms

Pickleball failures usually manifest in one of three forms:

Bootstrap errors: Pickleball fails to declare itself READY in the bootstrap log.

Listener errors: scripts/bridge-listener refuses to start, hangs, or crashes with syntax errors.

Ritual failures: The riot-act ritual does not trigger, hangs, or produces no output.


The first task of the Cyborg is classification: identify which arena the failure belongs to.


---

2. Inspecting Bootstrap

Run:

tail -n 20 var/logs/bootstrap.latest.log

✅ means a tool or hook was confirmed.

WARN indicates something degraded but not fatal.

ERR signals a missing dependency or configuration.


If bootstrap fails:

Check that essential tools (jq, mkfifo, git) exist in PATH.

Verify runtime directories (var/Pickleball/run) are present and writable.


Only when the bootstrap summary shows READY should you proceed to the listener.


---

3. Verifying the Listener

The listener is your live patch bridge. It is minimal by design, but fragile if mis-wired.

a. Repo Root Resolution

Most failures in logs like:

Not inside a git repository.

or

cd: ... No such file or directory

come from resolve_repo_root.
Check what path it resolved to:

grep 'started repo=' ~/.Pickleball/bridge/listener.log

It must point to the actual Pickleball repo root (the one containing .git).
If it resolves to $HOME or a duplicate line, fix the resolver to head -n1 | tr -d '\r'.

b. Syntax Errors

If you see:

syntax error near unexpected token '('

the culprit is usually over-complex Bash pattern matching (extglob, nested case patterns).
Simplify: use a single regex match or a case-insensitive string comparison.
For example, riot-act matching reduced to:

riot_trigger_match() {
  local t; t="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  [[ "$t" =~ ^[[:space:]]*read[[:space:]]+the[[:space:]]+riot[[:space:]]+act[[:space:]]*$ ]]
}

This alone eliminated half a day of churn.

c. FIFO Behavior

If the listener hangs, confirm the FIFO:

ls -l ~/.Pickleball/bridge/inbox.patch

It must be a p (pipe). If not, remove and re-create:

rm -f ~/.Pickleball/bridge/inbox.patch
mkfifo ~/.Pickleball/bridge/inbox.patch


---

4. Riot-Act Ritual Debugging

The riot-act ritual is sacred: it streams all context and affirms alignment with “I get it”.
When debugging it:

1. Confirm the dump script exists and is executable:

ls -l tools/read_contexts.sh


2. Check listener logs for riot-act dump via ....


3. If it hangs, ensure the dump script prints and exits; add set -x for tracing.



Rate-limiting is handled by EXC_RIOT_MIN_SECS. If you trigger repeatedly too fast, you’ll see riot-act suppressed (rate limited) in the logs.


---

5. JSON Report & Artifacts

Every run leaves behind:

~/.Pickleball/bridge/last_applied.txt – the raw artifact from FIFO.

~/.Pickleball/bridge/last_run.json – structured outcome (ok, mode, error).


Inspect with:

jq . ~/.Pickleball/bridge/last_run.json

This is how the Cyborg confirms what mode fired (patch, rp-fullfile, riot-act, or store-only).


---

6. Core Principles for the Cyborg

Whole files, not snippets. Snippets breed churn.

Simplify matches. Over-clever Bash leads to parse errors under Termux.

Inspect artifacts. Always read logs and saved JSON before touching code.

Honor rituals. Riot-act must be real, never faked.



---

7. Recovery Sequence

If the listener becomes corrupted:

1. Kill the process:

pkill -f bridge-listener


2. Clear lock + FIFO:

rm -f ~/.Pickleball/bridge/listener.pid ~/.Pickleball/bridge/inbox.patch


3. Re-bootstrap:

scripts/bootstrap


4. Restart listener:

scripts/bridge-listener



The cycle repeats until stability is restored.




