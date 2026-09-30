#!/usr/bin/env python3
"""Safely render a broker environment file from its tracked template.

Values are read from the process environment and are never written to stdout.
"""

from __future__ import annotations

import os
import re
import shlex
import stat
import sys
import tempfile
from pathlib import Path


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


if len(sys.argv) < 4:
    fail("usage: write-broker-env.py TEMPLATE OUTPUT VARIABLE [VARIABLE ...]")

template = Path(sys.argv[1])
output = Path(sys.argv[2])
variables = sys.argv[3:]

if not template.is_file():
    fail(f"template does not exist: {template}")

values: dict[str, str] = {}
for variable in variables:
    value = os.environ.get(variable)
    if not value:
        fail(f"required value {variable} is empty")
    values[variable] = value

content = template.read_text(encoding="utf-8")
for variable, value in values.items():
    pattern = re.compile(rf"^{re.escape(variable)}=.*$", re.MULTILINE)
    if len(pattern.findall(content)) != 1:
        fail(f"template must contain exactly one assignment for {variable}")
    replacement = f"{variable}={shlex.quote(value)}"
    content = pattern.sub(lambda _: replacement, content)

output.parent.mkdir(parents=True, exist_ok=True)
fd, temporary_name = tempfile.mkstemp(prefix=f".{output.name}.", dir=output.parent)
temporary = Path(temporary_name)
try:
    os.fchmod(fd, stat.S_IRUSR | stat.S_IWUSR)
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write(content)
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, output)
    os.chmod(output, stat.S_IRUSR | stat.S_IWUSR)
except Exception:
    temporary.unlink(missing_ok=True)
    raise