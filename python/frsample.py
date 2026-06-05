"""Python wrapper around the DJI ``FRSample`` flight-record parser.

This is meant to run **inside the repo's Docker image**, where the compiled
``FRSample`` binary lives at ``/app/FRSample``. It shells out to that binary,
which parses a DJI V13 flight-record ``.txt`` file (contacting DJI's keychain
server to decrypt it) and prints JSON to stdout:

* success -> ``{"summary": {...}, "info": {...}}``
* failure -> ``{}``  (with a human-readable reason on stderr)

So this wrapper parses stdout as JSON and treats an empty object as failure,
surfacing the stderr text in the raised exception.

Usage inside the container::

    from frsample import parse_flight_record

    result = parse_flight_record("/data/flight.txt", sdk_key="YOUR_KEY")
    print(result["summary"])

``SDK_KEY`` is read from the environment by default, so in the container you can
just set ``-e SDK_KEY=...`` and call ``parse_flight_record(path)``.
"""

from __future__ import annotations

import json
import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional, Union

# FRSample's department argument: "0" -> SDK department, anything else -> APP.
_DEPARTMENT_ARG = {"sdk": "0", "app": "1"}

# Where the binary lives in the Docker image (overridable via $FRSAMPLE_BIN).
_DEFAULT_BINARY = os.environ.get("FRSAMPLE_BIN", "/app/FRSample")

PathLike = Union[str, os.PathLike]


class FRSampleError(RuntimeError):
    """Raised when FRSample fails to parse a flight record.

    ``stderr`` holds FRSample's diagnostic message; ``returncode`` its exit code.
    """

    def __init__(self, message: str, *, stderr: str = "",
                 returncode: Optional[int] = None) -> None:
        super().__init__(message)
        self.stderr = stderr
        self.returncode = returncode


@dataclass
class FlightRecordParser:
    """Invokes the local FRSample binary and returns parsed flight-record JSON.

    Args:
        binary: Path to the FRSample executable. Defaults to ``$FRSAMPLE_BIN``
            or ``/app/FRSample``.
        sdk_key: DJI SDK/App key. Defaults to the ``SDK_KEY`` environment
            variable. Required -- FRSample contacts DJI to fetch decryption keys.
        department: ``"sdk"`` (default) or ``"app"``.
        timeout: Seconds to wait for FRSample (it makes a network call). ``None``
            waits indefinitely.
    """

    binary: PathLike = _DEFAULT_BINARY
    sdk_key: Optional[str] = None
    department: str = "sdk"
    timeout: Optional[float] = 120.0

    def __post_init__(self) -> None:
        if self.department not in _DEPARTMENT_ARG:
            raise ValueError(
                f"department must be one of {sorted(_DEPARTMENT_ARG)}, "
                f"got {self.department!r}"
            )
        if self.sdk_key is None:
            self.sdk_key = os.environ.get("SDK_KEY")

    def parse(self, log_path: PathLike) -> dict[str, Any]:
        """Parse a flight-record file and return the result as a dict.

        Returns the ``{"summary": ..., "info": ...}`` object on success.

        Raises:
            FileNotFoundError: if ``log_path`` does not exist.
            FRSampleError: if FRSample fails (empty result) or emits non-JSON.
        """
        log_path = Path(log_path).expanduser().resolve()
        if not log_path.is_file():
            raise FileNotFoundError(f"Flight record not found: {log_path}")
        if not self.sdk_key:
            raise FRSampleError(
                "No SDK key. Pass sdk_key=... or set the SDK_KEY env var; "
                "FRSample needs it to fetch decryption keys from DJI."
            )

        cmd = [str(self.binary), str(log_path), _DEPARTMENT_ARG[self.department]]
        env = {**os.environ, "SDK_KEY": self.sdk_key}
        try:
            proc = subprocess.run(
                cmd, env=env, capture_output=True,
                timeout=self.timeout, check=False,
            )
        except subprocess.TimeoutExpired as exc:
            raise FRSampleError(
                f"FRSample timed out after {self.timeout}s "
                "(it makes a network call to DJI -- check connectivity).",
                stderr=_decode(exc.stderr),
            ) from exc
        except FileNotFoundError as exc:
            raise FRSampleError(
                f"FRSample binary not found at {self.binary!r}. "
                "Set $FRSAMPLE_BIN or pass binary=...",
            ) from exc

        return self._parse_output(_decode(proc.stdout), _decode(proc.stderr),
                                  proc.returncode)

    def parse_to_file(self, log_path: PathLike, out_path: PathLike, *,
                      indent: Optional[int] = 2) -> Path:
        """Parse ``log_path`` and write the JSON result to ``out_path``."""
        result = self.parse(log_path)
        out_path = Path(out_path).expanduser()
        out_path.write_text(json.dumps(result, indent=indent))
        return out_path

    @staticmethod
    def _parse_output(stdout: str, stderr: str,
                      returncode: int) -> dict[str, Any]:
        text = stdout.strip()
        try:
            result = json.loads(text) if text else {}
        except json.JSONDecodeError as exc:
            raise FRSampleError(
                f"FRSample output was not valid JSON: {exc}",
                stderr=stderr, returncode=returncode,
            ) from exc

        # FRSample prints an empty object on failure (reason goes to stderr).
        if not result:
            reason = stderr.strip() or "FRSample returned no data"
            raise FRSampleError(
                f"FRSample failed: {reason}",
                stderr=stderr, returncode=returncode,
            )
        return result


def parse_flight_record(log_path: PathLike, **kwargs: Any) -> dict[str, Any]:
    """Convenience one-shot: ``parse_flight_record("/data/flight.txt")``.

    Accepts the same keyword args as :class:`FlightRecordParser`.
    """
    return FlightRecordParser(**kwargs).parse(log_path)


def _decode(raw: Optional[bytes]) -> str:
    return raw.decode("utf-8", errors="replace") if raw else ""


def _main(argv: Optional[list[str]] = None) -> int:
    import argparse
    import sys

    ap = argparse.ArgumentParser(
        description="Parse a DJI V13 flight record to JSON via FRSample.")
    ap.add_argument("log", help="Path to the flight-record .txt file")
    ap.add_argument("-o", "--out", help="Write JSON here instead of stdout")
    ap.add_argument("--binary", default=_DEFAULT_BINARY,
                    help="Path to the FRSample executable")
    ap.add_argument("--sdk-key", help="DJI SDK key (else $SDK_KEY)")
    ap.add_argument("--department", choices=sorted(_DEPARTMENT_ARG),
                    default="sdk")
    ap.add_argument("--timeout", type=float, default=120.0)
    args = ap.parse_args(argv)

    parser = FlightRecordParser(
        binary=args.binary, sdk_key=args.sdk_key,
        department=args.department, timeout=args.timeout,
    )
    try:
        if args.out:
            print(f"Wrote {parser.parse_to_file(args.log, args.out)}")
        else:
            print(json.dumps(parser.parse(args.log), indent=2))
    except (FRSampleError, FileNotFoundError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(_main())
