"""
Module entrypoint for `python -m Pickleball`.
Spins up the Starlette app via uvicorn using env defaults.
"""
from __future__ import annotations

import os
import uvicorn

def main() -> None:
    host = os.getenv("HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "8765"))
    uvicorn.run("Pickleball:app", host=host, port=port, reload=False, access_log=False)

if __name__ == "__main__":
    main()

