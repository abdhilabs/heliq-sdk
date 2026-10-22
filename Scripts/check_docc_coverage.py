#!/usr/bin/env python3
"""Fails when an exported Swift declaration lacks a preceding DocC comment."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "Sources" / "HeliqSDK"
PUBLIC_DECLARATION = re.compile(
    r"^\s*public\s+(?:final\s+|indirect\s+|nonisolated\s+)?(?:class|struct|enum|protocol|actor|extension|typealias|associatedtype|init|func|var|let|subscript|static\s+(?:let|var|func))\b"
)
PUBLIC_ENUM = re.compile(r"^\s*public\s+(?:indirect\s+)?enum\s+\w+")
PUBLIC_EXTENSION = re.compile(r"^\s*public\s+extension\s+\w+")
EXTENSION_MEMBER = re.compile(
    r"^\s*(?!public\b|private\b|fileprivate\b|internal\b)(?:static\s+)?(?:init|func|var|let|subscript)\b"
)
ENUM_CASE = re.compile(r"^\s*case\s+\w+")


def has_docc_before(lines: list[str], index: int) -> bool:
    cursor = index - 1
    while cursor >= 0:
        stripped = lines[cursor].strip()
        if not stripped or stripped.startswith("@"):
            cursor -= 1
            continue
        return lines[cursor].lstrip().startswith("///")
    return False


def main() -> int:
    missing: list[str] = []
    for path in sorted(SOURCE_ROOT.rglob("*.swift")):
        lines = path.read_text(encoding="utf-8").splitlines()
        inside_public_enum = False
        inside_public_extension = False
        brace_depth = 0
        for index, line in enumerate(lines):
            if PUBLIC_ENUM.match(line):
                inside_public_enum = True
                brace_depth = line.count("{") - line.count("}")
            elif PUBLIC_EXTENSION.match(line):
                inside_public_extension = True
                brace_depth = line.count("{") - line.count("}")
            elif inside_public_enum or inside_public_extension:
                brace_depth += line.count("{") - line.count("}")
                if brace_depth <= 0:
                    inside_public_enum = False
                    inside_public_extension = False

            is_public_declaration = PUBLIC_DECLARATION.match(line)
            is_public_enum_case = inside_public_enum and ENUM_CASE.match(line)
            is_public_extension_member = (
                inside_public_extension
                and brace_depth == 1
                and EXTENSION_MEMBER.match(line)
            )
            if (
                is_public_declaration
                or is_public_enum_case
                or is_public_extension_member
            ) and not has_docc_before(lines, index):
                missing.append(f"{path.relative_to(ROOT)}:{index + 1}: {line.strip()}")

    if missing:
        print("Missing DocC comments for public declarations:", file=sys.stderr)
        print("\n".join(missing), file=sys.stderr)
        return 1

    print("DocC public-symbol coverage audit passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
