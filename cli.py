import typer
import subprocess
import datetime as _dt
import os, requests
from Pickleball import utils
from Pickleball.utils import _api_base

app = typer.Typer()

@app.command("version")
def version(json_out: bool = typer.Option(False, "--json", help="Output as JSON")) -> None:
    info = utils.version()
    if json_out:
        import json
        typer.echo(json.dumps(info, indent=2))
    else:
        typer.echo(info)

@app.command("health")
def health() -> None:
    typer.echo(utils.health())

@app.command("get")
def get(path: str = typer.Argument(..., help="Repo-relative path to fetch")) -> None:
    text = utils.get(path)
    typer.echo(text, nl=False)

@app.command("apply")
def apply(path: str = typer.Argument(..., help="Local file path to upload")) -> None:
    resp = utils.sendfile(path)
    typer.echo(f"{path}: {resp.status_code}")

@app.command("ls")
def ls(dirpath: str = typer.Argument(".", help="Directory to list")) -> None:
    for e in utils.listdir(dirpath):
        typer.echo(e)

@app.command("eval")
def eval_(
    cmd: str = typer.Argument(..., help="Shell command to run and capture"),
    title: str = typer.Option("report", "--title", "-t", help="Label for saved report"),
) -> None:
    """
    Run a shell command (string), show stdout/stderr locally,
    and upload the combined output into repo inbox as Markdown.
    """
    proc = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    out, err, code = proc.stdout, proc.stderr, proc.returncode

    if out:
        typer.echo(out, nl=not out.endswith("\n"))
    if err:
        typer.echo(err, err=True, nl=not err.endswith("\n"))

    ts = _dt.datetime.utcnow().strftime("%Y%m%d-%H%M%S")
    payload = "\n".join(
        [
            f"# {title}",
            "",
            f"Generated: {_dt.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}",
            f"Command: `{cmd}`",
            f"Exit code: {code}",
            "",
            "## stdout",
            "```",
            out.rstrip("\n"),
            "```",
            "",
            "## stderr",
            "```",
            (err.rstrip("\n") or "(empty)"),
            "```",
            "",
        ]
    )
    dest = f"inbox/{ts}-{title.replace(' ', '_')}.md"

    headers = {"Content-Type": "text/plain; charset=utf-8", "X-Path": dest}
    token = os.environ.get("EX_TOKEN") or os.environ.get("EXCALIBUR_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"

    r = requests.post(f"{_api_base()}/apply", headers=headers, data=payload.encode("utf-8"), timeout=(10, 30))
    r.raise_for_status()
    typer.echo(f"OK -> {dest}")
