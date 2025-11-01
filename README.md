# Pickleball

## Quickstart
cd Pickleball
pip install -r requirements.txt
make bootstrap
make check

## Usage Examples
# Show CLI help
python cli.py --help

# Show version info
python cli.py version

# Dump config (masked by default)
python cli.py config

# Run health checks
python cli.py doctor

# After installing in editable mode
pip install -e .
Pickleball --help
Pickleball version
Pickleball config --no-mask
Pickleball doctor

## Quality
make lint
make type
make fmt
pre-commit install


## State & Logs

Pickleball keeps its own health records:

State JSON (latest snapshot):

var/state/bootstrap.json — environment + toolchain contract.

var/state/diagnostic.json — extended system + repo checks.

Each run overwrites the previous file (always “latest truth”).


Logs (history, human-readable):

var/logs/bootstrap.YYYYMMDD-HHMMSS.log

var/logs/diagnostic.YYYYMMDD-HHMMSS.log

bootstrap.latest.log / diagnostic.latest.log symlinks (copy fallback on Android FS).



These files are idempotent checkpoints: JSON is for machines, logs are for humans. Both update on every run. Exit codes: 0 = clean, 2 = warnings only, 1 = errors.







