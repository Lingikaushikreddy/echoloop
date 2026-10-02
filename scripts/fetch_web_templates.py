#!/usr/bin/env python3
"""Download only Godot's single-threaded web export templates.

The official export-template archive is about 1.3 GB. It is a zip file, so this
script reads its index with HTTP range requests and extracts only the three files
the web export needs (about 20 MB). Needs only Python 3 and curl.

Usage: fetch_web_templates.py <godot-version> <destination-dir>
"""
import os
import re
import subprocess
import sys
import zipfile

WANTED = (
    "templates/web_nothreads_debug.zip",
    "templates/web_nothreads_release.zip",
    "templates/version.txt",
)
CHUNK = 8 * 1024 * 1024


def curl(*args):
    return subprocess.run(["curl", "-sSfL", *args], check=True, capture_output=True).stdout


class HttpRangeFile:
    """A read-only, seekable file over HTTP range requests, with an 8 MB read-ahead buffer."""

    def __init__(self, url):
        # A 1-byte request follows GitHub's redirect to the signed CDN URL and
        # reveals the archive size in the Content-Range header.
        out = curl("-r", "0-0", "-o", os.devnull, "-D", "-", "-w", "%{url_effective}", url).decode()
        self.size = int(re.findall(r"(?im)^content-range: bytes 0-0/(\d+)", out)[-1])
        self.url = out.strip().splitlines()[-1]
        self.pos = 0
        self.buf_start = 0
        self.buf = b""

    def seekable(self):
        return True

    def tell(self):
        return self.pos

    def seek(self, offset, whence=0):
        base = {0: 0, 1: self.pos, 2: self.size}[whence]
        self.pos = base + offset
        return self.pos

    def read(self, n=-1):
        if n is None or n < 0:
            n = self.size - self.pos
        n = min(n, self.size - self.pos)
        if n <= 0:
            return b""
        buf_end = self.buf_start + len(self.buf)
        if not (self.buf_start <= self.pos and self.pos + n <= buf_end):
            end = min(self.pos + max(n, CHUNK), self.size) - 1
            self.buf = curl("-r", f"{self.pos}-{end}", self.url)
            self.buf_start = self.pos
        offset = self.pos - self.buf_start
        data = self.buf[offset:offset + n]
        self.pos += len(data)
        return data


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    version, dest = sys.argv[1], os.path.expanduser(sys.argv[2])
    url = (
        f"https://github.com/godotengine/godot/releases/download/{version}-stable/"
        f"Godot_v{version}-stable_export_templates.tpz"
    )
    os.makedirs(dest, exist_ok=True)
    with zipfile.ZipFile(HttpRangeFile(url)) as archive:
        for name in WANTED:
            target = os.path.join(dest, os.path.basename(name))
            with archive.open(name) as src, open(target, "wb") as out:
                out.write(src.read())
            print(f"{target}  {os.path.getsize(target)} bytes")


if __name__ == "__main__":
    main()
