#!/usr/bin/env -S nix develop .#ci -c bash

set -exuo pipefail

SCRIPT_DIR=$(dirname "$0")
GITHUB_TOKEN=${1:-}

curl_github () {
  CURL_ARGS=(-L --retry 5 -H "Accept: application/vnd.github.v3+json")
  if [ "${GITHUB_TOKEN}" != "" ]; then
    CURL_ARGS+=(-H "Authorization: token $GITHUB_TOKEN")
  fi
  curl "${CURL_ARGS[@]}" "$@"
}

tags(){
  curl_github "https://api.github.com/repos/gohugoio/hugo/git/refs/tags" | \
    jq -r ".[].ref" | \
    sed "s|refs/tags/v\(.*\)|\1|g" | \
    sort -V -r
}

mkdir -p "$SCRIPT_DIR"/../versions

TMP=$(mktemp)


cleanup(){
  rm "$TMP"
}
trap cleanup EXIT

tags > "$TMP"

while read -r tag; do
  OUT="$SCRIPT_DIR/../versions/$tag.json"
  [ -f "$OUT" ] && continue # skip version if file exists
  URL="https://github.com/gohugoio/hugo/releases/download/v$tag/hugo_$tag""_checksums.txt"
  python "$SCRIPT_DIR/extract_versions.py" "$tag" <(curl_github "$URL") "$OUT" || true
done < "$TMP"

head -n 1 "$TMP" > "$SCRIPT_DIR/../versions/latest"
