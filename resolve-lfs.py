#!/usr/bin/env python3
"""Replace Git LFS pointer files with real content via the GitHub LFS batch API.

Works without git-lfs. Scans the tree, detects LFS pointer files (first line
"version https://git-lfs.github.com/spec/v1"), requests a signed download URL
from the repository's LFS batch endpoint, downloads the object, verifies its
sha256 against the pointer, and overwrites the file.

Exit code 0 on success, 1 if any file failed.
"""
import hashlib
import json
import os
import sys
import urllib.request

REPO = "NTNewHorizons/NTNH-Server"
BATCH_URL = "https://github.com/{}.git/info/lfs/objects/batch".format(REPO)
POINTER_LINE = "version https://git-lfs.github.com/spec/v1"
RETRIES = 3


def is_pointer(path):
    try:
        with open(path, "rb") as fh:
            head = fh.read(256)
        first = head.split(b"\n", 1)[0].decode("utf-8", "replace").strip()
        return first == POINTER_LINE
    except OSError:
        return False


def parse_pointer(path):
    oid = None
    size = None
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if line.startswith("oid sha256:"):
                oid = line.split(":", 1)[1].strip()
            elif line.startswith("size "):
                size = int(line.split(" ", 1)[1])
    return oid, size


def download(oid, size, dest):
    body = json.dumps({
        "operation": "download",
        "transfers": ["basic"],
        "objects": [{"oid": oid, "size": size}],
    }).encode("utf-8")
    headers = {
        "Accept": "application/vnd.git-lfs+json",
        "Content-Type": "application/json",
    }
    last_error = None
    for attempt in range(1, RETRIES + 1):
        try:
            req = urllib.request.Request(BATCH_URL, data=body, headers=headers, method="POST")
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            href = data["objects"][0]["actions"]["download"]["href"]
            tmp = dest + ".download"
            urllib.request.urlretrieve(href, tmp)
            hasher = hashlib.sha256()
            with open(tmp, "rb") as fh:
                for chunk in iter(lambda: fh.read(1 << 20), b""):
                    hasher.update(chunk)
            if hasher.hexdigest() != oid:
                os.remove(tmp)
                raise RuntimeError("sha256 mismatch")
            os.replace(tmp, dest)
            return True
        except Exception as exc:  # noqa: BLE001
            last_error = exc
            print("    attempt {} failed: {}".format(attempt, exc), file=sys.stderr)
    if last_error:
        print("    FAILED: {}".format(last_error), file=sys.stderr)
    return False


def main():
    root = os.getcwd()
    failures = 0
    resolved = 0
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d != ".git"]
        for name in filenames:
            path = os.path.join(dirpath, name)
            if not is_pointer(path):
                continue
            oid, size = parse_pointer(path)
            rel = os.path.relpath(path, root)
            print("  Downloading: {} ({} bytes)".format(rel, size))
            if oid and size and download(oid, size, path):
                resolved += 1
                print("    OK")
            else:
                failures += 1
    print("Resolved {} file(s).".format(resolved))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
