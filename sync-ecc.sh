#!/usr/bin/env bash
# Rebuild plugins/ecc from an upstream ECC release: only the paths in ecc-include.txt, no hooks or MCP servers.
# Usage: ./sync-ecc.sh <tag>   (e.g. ./sync-ecc.sh v2.2.3), then review `git diff` before committing.
set -euo pipefail
tag=${1:?usage: $0 <tag>}
root=$(cd "$(dirname "$0")" && pwd)
dest=$root/plugins/ecc
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

git -c advice.detachedHead=false clone -q --depth 1 --branch "$tag" https://github.com/affaan-m/ECC.git "$tmp/ECC"
sha=$(git -C "$tmp/ECC" rev-parse HEAD)

rm -rf "$dest"
mkdir -p "$dest/.claude-plugin"
cp "$tmp/ECC/LICENSE" "$dest/"
grep -vE '^\s*(#|$)' "$root/ecc-include.txt" | while read -r path; do
  [ -e "$tmp/ECC/$path" ] || { echo "missing upstream: $path" >&2; exit 1; }
  mkdir -p "$dest/$(dirname "$path")"
  cp -r "$tmp/ECC/$path" "$dest/$path"
done
python3 -I - "$tmp/ECC/.claude-plugin/plugin.json" "$dest/.claude-plugin/plugin.json" "$tag" "$sha" <<'EOF'
import json, sys
src, out, tag, sha = sys.argv[1:]
m = json.load(open(src))
for k in ("hooks", "mcpServers", "lspServers", "userConfig"):
    m.pop(k, None)
m["description"] = f"ECC {tag} ({sha[:7]}): selected agents, skills and commands (ecc-include.txt), no hooks or MCP servers"
with open(out, "w") as f:
    json.dump(m, f, indent=2)
    f.write("\n")
EOF
echo "$tag $sha" > "$dest/UPSTREAM"
echo "plugins/ecc = ECC $tag ($sha), $(grep -cvE '^\s*(#|$)' "$root/ecc-include.txt") paths"
