"""
Pickleball sitecustomize:
Global compatibility shim for Click API change:
  TypeError: Parameter.make_metavar() missing 1 required positional argument: 'ctx'

Python auto-imports `sitecustomize` if it is importable on sys.path.
This shim adapts to both old and new Click signatures and provides a safe fallback.
It is intentionally no-op if Click is not installed, to avoid exiting test runs.
"""
from __future__ import annotations

try:
    # If Click is not installed, quietly do nothing.
    import click  # type: ignore
    from click.core import Parameter  # type: ignore
except Exception:
    click = None  # type: ignore
    Parameter = None  # type: ignore

if Parameter is not None:
    _ORIG_make_metavar = getattr(Parameter, "make_metavar", None)

    def _excalibur_make_metavar(self: "Parameter", ctx=None, *args, **kwargs):
        """
        Compatible wrapper:
        - If original supports the provided call, use it.
        - Otherwise, synthesize a reasonable metavar:
            prefer self.metavar; else type.get_metavar(self) if present;
            else type.name.upper(); else self.name.upper(); else "VALUE".
        """
        if _ORIG_make_metavar is not None:
            try:
                if ctx is None:
                    return _ORIG_make_metavar(self)  # old Click
                else:
                    return _ORIG_make_metavar(self, ctx)  # new Click
            except TypeError:
                pass  # fall through to synthesis

        mv = getattr(self, "metavar", None)
        if mv:
            return mv

        t = getattr(self, "type", None)
        if t is not None:
            get_mv = getattr(t, "get_metavar", None)
            if callable(get_mv):
                try:
                    return get_mv(self)
                except Exception:
                    pass
            name = getattr(t, "name", None)
            if isinstance(name, str) and name:
                return name.upper()

        name = getattr(self, "name", None)
        if isinstance(name, str) and name:
            return name.upper()

        return "VALUE"

    try:
        if _ORIG_make_metavar is not None:
            Parameter.make_metavar = _excalibur_make_metavar  # type: ignore[assignment]
    except Exception:
        # Ignore — better to run than fail import
        pass
