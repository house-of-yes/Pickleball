Pickleball/labs/aider_quickstart.md
# Aider Quickstart (Claude-only, Termux/Unix friendly)

This path avoids heavy builds (e.g., tiktoken/Rust) by using **Anthropic only**.

## 1) Prereqs
- Python 3.10+ and `git` installed
- Run these from your repo root (e.g., `~/HouseOfYes`)

## 2) (Optional) Virtualenv

    python -m venv .venv
    . .venv/bin/activate
    python -m pip install --upgrade pip setuptools wheel

## 3) Install Aider (Claude-only)

    python -m pip install "aider-chat[anthropic]"

## 4) Set your API key

    export ANTHROPIC_API_KEY="sk-ant-..."

## 5) Run Aider in this repo

    aider --model claude-3-5-sonnet-latest

### Scope it to one file (recommended)

    aider king_of_swing/bin/dashboard

## 6) Typical cycle

    clean && pytest -q
    git add -A && git commit -m "chore: apply aider edits"
    git push

Notes:
- If you later want OpenAI/GPT in Aider, you’ll likely need `tiktoken` (Rust toolchain). Staying Claude-only avoids those builds on Termux.
- Keep your API key in your shell profile if desired:

    echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc
