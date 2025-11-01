# Pickleball

Pickleball is a daemon + CLI for editing, testing, and interacting with code from anywhere.  

OIt runs as a background service and exposes a simple HTTP+WS API.  

## ⚡ Test Scope Strategy

Pickleball integrates directly with your test suite. By default, it runs *targeted fast tests* while you’re iterating, and the *full suite* before any commit.

### Default (smart mode)
- **On apply:** run only tests most likely to be affected  
  (same module, matching test files, `--last-failed` cache).  
- **On commit:** full project suite is required green before the commit lands.

### Config (via env)
| Variable                  | Values                 | Default  | Notes                                             |
|---------------------------|------------------------|----------|---------------------------------------------------|
| `EXCALIBUR_TEST_SCOPE`    | `full` \| `changed` \| `smart` | `smart`  | `full`: always whole suite. `changed`: only targeted subset. `smart`: subset on apply, full on commit. |
| `EXCALIBUR_TEST_CMD`      | custom command string  | `pytest` | Base test runner.                                 |
| `EXCALIBUR_TEST_TIMEOUT`  | seconds                | `30`     | Kill tests that exceed this runtime.              |
| `EXCALIBUR_TEST_SELECTORS`| globs/comma-sep        | *(none)* | Override auto-detection; e.g. `tests/unit,tests/foo`. |
| `EXCALIBUR_PYTEST_ARGS`   | extra args             | *(none)* | Extra args; e.g. `-n auto` for parallel runs with `xdist`. |

### Transparency
Each run reports the chosen scope:
[ok] Test scope: subset (tests/pkg/test_foo.py, tests/test_math.py)
[ok] 5 passed in 0.42s

On commit, you’ll always see:
[ok] Test scope: full suite
[ok] 124 passed in 12.3s

This keeps iteration fast while guaranteeing correctness at the commit wall.

The xcal command provides a lean interface to send files, fetch them back, and check health/version.

---

## Setup (Termux)

1. Clone this repo and enter it:
   ```bash
   git clone <your-repo-url>
   cd HouseOfYes/Pickleball
