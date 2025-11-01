Understood — here is the file as plain text, no nested code blocks inside.


---

context/checklist-listener.md

Listener Test Checklist

When the listener is running, test each mode in turn to confirm it handles artifacts correctly.


---

1. Riot Act Ritual

Send:
printf 'read the riot act\n' > ~/.Pickleball/bridge/inbox.patch

Expect:

Listener log shows riot-act dump via ....

Context files stream to stdout.

Ends with I get it.



---

2. Patch Mode

Send:
printf '--- a/fake.txt\n+++ b/fake.txt\n' > ~/.Pickleball/bridge/inbox.patch

Expect:

Listener tries to apply as patch.

Fails (since file doesn’t exist).

Banner shows PATCH FAILED.



---

3. rp-fullfile Mode

Send:
printf 'test.txt\nbash\necho hello\n\n' > ~/.Pickleball/bridge/inbox.patch

Expect:

Listener writes a new file test.txt with content echo hello.

Banner shows ARTIFACT HANDLED.

Check file exists with: cat test.txt



---

4. Oversized Artifact

Send:
head -c 6000000 /dev/zero > ~/.Pickleball/bridge/inbox.patch

Expect:

Listener rejects artifact (too-large).

Banner shows ARTIFACT NOT APPLIED.



---

5. Read-Only Mode

Run listener with:
EXC_READONLY=1 scripts/bridge-listener

Send:
printf '--- a/fake.txt\n+++ b/fake.txt\n' > ~/.Pickleball/bridge/inbox.patch

Expect:

Listener refuses with read-only mode.

No changes applied.



---

6. JSON Report Check

After any test, inspect:
jq . ~/.Pickleball/bridge/last_run.json

Expect:

mode field matches test (riot, patch, rp-fullfile, etc.).

ok true/false matches outcome.



---

Principles:

Test all 5 modes after listener changes.

Always verify last_run.json to confirm mode detection.

Riot Act test proves ritual path is alive.



