import json
import subprocess
import sys

version = sys.argv[1]

with open(sys.argv[2]) as f:
    checksums = f.readlines()

data = {}


def get_nix_hash(row: str):
    sha256_raw = row.split()[0]
    cmd = subprocess.run(
        ["nix", "hash", "convert", "--hash-algo", "sha256", "--to", "sri", sha256_raw],
        capture_output=True,
    )
    return cmd.stdout.decode().strip()


def gen_entry(c: str):
    return {
        "url": f"https://github.com/gohugoio/hugo/releases/download/v{version}/{c.split()[1]}",
        "hash": get_nix_hash(c),
    }


for c in checksums:
    c = c.lower()
    arch = []
    if "tar.gz" not in c:
        continue
    if "linux" in c:
        if "amd64" in c or "64bit" in c or "x64" in c:
            arch = ["x86_64-linux"]
        if "arm64" in c:
            arch = ["aarch64-linux"]
    elif "darwin" in c or "macos" in c:
        if "universal" in c:
            arch = ["x86_64-darwin", "aarch64-darwin"]
        elif "arm64" in c:
            arch = ["aarch64-darwin"]
        elif "64bit" in c or "x64" in c:
            arch = ["x86_64-darwin"]
    else:
        continue

    kind = "default"
    if "withdeploy" in c:
        kind = "extended_withdeploy"
    elif "extended" in c:
        kind = "extended"

    for a in arch:
        if kind not in data:
            data[kind] = {}
        data[kind][a] = gen_entry(c)

if data == {}:
    raise RuntimeError("no matching files")

with open(sys.argv[3], "w") as f:
    json.dump(data, f)
