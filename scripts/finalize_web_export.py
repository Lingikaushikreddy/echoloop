#!/usr/bin/env python3
"""Give the web game package a content version so cached builds cannot mix."""
import hashlib
import pathlib
import sys


def finalize(directory: pathlib.Path) -> None:
    version = hashlib.sha256((directory / "index.pck").read_bytes()).hexdigest()[:16]
    page = directory / "index.html"
    text = page.read_text(encoding="utf-8")
    marker = "__YESTERSELF_PACK_HASH__"
    if marker not in text:
        raise ValueError("The exported HTML is missing its package version marker")
    page.write_text(text.replace(marker, version), encoding="utf-8")


if __name__ == "__main__":
    finalize(pathlib.Path(sys.argv[1]))
