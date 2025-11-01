# CLI Examples

These assume you’ve installed with:

pip install -e .

which exposes the `xcal` command.

---

## Show version
xcal version

## Check health
xcal health

## Upload a file (apply)
xcal apply Pickleball/utils.py

## Dry run upload (validation only)
xcal apply --dry-run Pickleball/utils.py

## Fetch a file
xcal get Pickleball/utils.py

## List directory contents
xcal ls Pickleball

## Diff local vs remote
xcal diff Pickleball/utils.py Pickleball/utils.py
