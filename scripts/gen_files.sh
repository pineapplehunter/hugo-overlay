#! /usr/bin/env nix-shell
#! nix-shell -i bash --pure --packages cacert curl jq python3 nix

set -exuo pipefail

SCRIPT_DIR=$(dirname "$0")

tags(){
  curl -L "https://api.github.com/repos/gohugoio/hugo/git/refs/tags" | \
    jq -r ".[].ref" | \
    sed "s|refs/tags/v\(.*\)|\1|g" | \
    sort -V -r
}

mkdir -p "$SCRIPT_DIR"/../versions

TMP=$(mktemp)

tags > "$TMP"

while read -r tag; do
  OUT="$SCRIPT_DIR/../versions/$tag.json"
  [ -f "$OUT" ] && continue # skip version if file exists
  URL="https://github.com/gohugoio/hugo/releases/download/v$tag/hugo_$tag""_checksums.txt"
  python "$SCRIPT_DIR/extract_versions.py" "$tag" <(curl -L "$URL") "$OUT" || true
done < "$TMP"

head -n 1 "$TMP" > "$SCRIPT_DIR/../versions/latest"
